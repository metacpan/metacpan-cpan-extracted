package Plack::App::MCCS;

use v5.36;

our $VERSION = "2.002000";
$VERSION = eval $VERSION;

use parent qw/Plack::Component/;

use autodie;
use Cwd   ();
use Fcntl qw/:flock/;
use File::Spec;
use HTTP::Date;
use IO::Compress::Gzip;
use IO::Compress::Deflate;
use Module::Load::Conditional qw/can_load/;
use Plack::MIME;
use Plack::Util;
use Plack::Util::Accessor qw/
  root
  minify
  compress
  etag
  types
  charset
  index_files
  ignore_file
  default_valid_for
  default_cache_control
  min_cache_dir
  vhost_mode
  _minifiers
  _compressors
  _ignore_matchers
  /;
use Text::Gitignore qw/build_gitignore_matcher/;

=head1 NAME

Plack::App::MCCS - Use mccs in Plack applications.

=head1 EXTENDS

L<Plack::Component>

=head1 SYNOPSIS

	# in your app.psgi:
	use Plack::Builder;
	use Plack::App::MCCS;

	my $app = sub { ... };

	# be happy with the defaults:
	builder {
		mount '/static' => Plack::App::MCCS->new(root => '/path/to/static_files')->to_app;
		mount '/' => $app;
	};

	# or tweak the app to suit your needs:
	builder {
		mount '/static' => Plack::App::MCCS->new(
			root => '/path/to/static_files',
			min_cache_dir => 'min_cache',
            default_valid_for => 86400,
            default_cache_control => ['private'],
			types => {
				'.htc' => {
					content_type => 'text/x-component',
					valid_for => 360,
					cache_control => ['no-cache', 'must-revalidate'],
				},
			},
		)->to_app;
		mount '/' => $app;
	};

=head1 DESCRIPTION

C<Plack::App::MCCS> is a L<Plack> fully-featured static file server. Refer to
L<mccs> for more information. This package allows embedding C<mccs> in a PSGI
application.

=head1 CLASS METHODS

=head2 new( %opts )

Creates a new instance of this module. The following options are supported, all
are optional:

=over

=item * B<root>: The path to the root directory where static files reside.
Defaults to the current working directory.

=item * B<charset>: the character set to append to content-type headers when
text files are returned. Defaults to "UTF-8".

=item * B<minify>: boolean value indicating whether C<mccs> should automatically
minify CSS/JS files (or search for pre-minified files). Defaults to true.

=item * B<compress>: boolean value indicating whether C<mccs> should
automatically compress files (or search for pre-compressed files). Defaults to
true.

=item * B<etag>: boolean value indicating whether C<mccs> should automatically
create and save ETags for files. Defaults to true. If false, C<mccs> will NOT
handle ETags at all (so if the client sends the C<If-None-Match> header,
C<mccs> will ignore it).

=item * B<vhost_mode>: boolean value indicating whether to enable virtual-hosts
mode. When enabled, multiple websites can be served based on the HTTP Host
header. HTTP/1.0 requests will not be supported in this mode. The root directory
must contain subdirectories named after each host/domain to serve in this mode.
Defaults to false.

=item * B<min_cache_dir>: by default, minified files are generated in the same
directory as the original file. If this attribute is specified they
are instead generated within the provided subdirectory, and minified files
outside that directory are ignored, unless requested directly.

=item * B<default_valid_for>: the default number of seconds caches are allowed
to save a response. Defaults to 86400 seconds (one day).

=item * B<default_cache_control>: an array-ref of options for the
C<Cache-Control> header (all options are accepted except for C<max-age>, which
is automatically calculated from the resource's C<valid_for> setting). Defaults
to C<['public']>.

=item * B<index_files>: a list of file names to search for when a directory is
requested. Defaults to C<['index.html']>.

=item * B<ignore_file>: path to a file in the format of the L<Gitignore|https://git-scm.com/docs/gitignore>
file. Any request that matches rules in this file will not be served by C<mccs>
and instead return a 404 Not Found response. Defaults to C<'.mccsignore'>. In
vhost_mode, every host may have its own file, and there can also be a global
file for all hosts. Both the host-specific file and the global file will be used
if they exist.

=item * B<types>: a hash-ref to supply options specific to file extensions.
Keys are extensions (beginning with a dot). Values can be B<valid_for> (for
the cache validity interval in seconds); B<cache_control> (for an array-ref
of Cache-Control options); B<content_type> to provide a Content-Type when
C<mccs> can't accurately guess it.

=back

If you don't want something to be cached, give the global B<default_valid_for>
or the extension-specific B<valid_for> options a value of either zero, or
preferably any number lower than zero, which will cause C<mccs> to set an
C<Expires> header way in the past. You should also pass the B<cache_control>
option C<no_store> and probably C<no_cache>. When C<mccs> encounteres the
C<no_store> option, it does not automatically add the C<max-age> option
to the C<Cache-Control> header.

=cut

our $DEFAULT_VALID_FOR = 86400;
our $DEFAULT_CHARSET   = "UTF-8";

sub new ( $class, %opts ) {
    $opts{root}    ||= Cwd::getcwd();
    $opts{charset} ||= $DEFAULT_CHARSET;
    $opts{default_valid_for} = $DEFAULT_VALID_FOR
      if !exists $opts{default_valid_for};
    $opts{default_cache_control} ||= ['public'];
    $opts{index_files}           ||= ['index.html'];
    $opts{minify}     = 1 if !defined $opts{minify};
    $opts{compress}   = 1 if !defined $opts{compress};
    $opts{etag}       = 1 if !defined $opts{etag};
    $opts{vhost_mode} = 0 if !defined $opts{vhost_mode};
    $opts{ignore_file} ||= '.mccsignore';
    $opts{types}       ||= {};

    my $self = $class->SUPER::new(%opts);

    $self->{_minifiers}       = {};
    $self->{_compressors}     = {};
    $self->{_ignore_matchers} = {};

    # Are we minifying files? If so, which types do we support?
    if ( $self->minify ) {
        if ( can_load( modules => { 'JavaScript::Minifier::XS' => 0.15 } ) ) {
            $self->{_minifiers}->{js} = 1;
        }
        if ( can_load( modules => { 'CSS::Minifier::XS' => 0.13 } ) ) {
            $self->{_minifiers}->{css} = 1;
        }
    }

    # Are we compressing files? if so, which algorithms do we support?
    if ( $self->compress ) {
        if ( can_load( modules => { 'IO::Compress::Gzip' => undef } ) ) {
            $self->{_compressors}->{gzip} = 1;
        }
        if ( can_load( modules => { 'IO::Compress::Deflate' => undef } ) ) {
            $self->{_compressors}->{deflate} = 1;
        }
        if ( can_load( modules => { 'IO::Compress::Zstd' => undef } ) ) {
            $self->{_compressors}->{zstd} = 1;
        }
    }

    # load and parse ignore files, if they exist
    $self->_load_ignore_files();

    return $self;
}

=head1 OBJECT METHODS

=head2 call( \%env )

L<Plack> automatically calls this method to handle a request. This is where
the magic (or disaster) happens.

=cut

sub call ( $self, $env ) {
    my $path_info =
        $self->vhost_mode
      ? $env->{HTTP_HOST} . $env->{PATH_INFO}
      : $env->{PATH_INFO};

    # check if path is ignored by any relevant ignore files
    if (
        (
               $self->vhost_mode
            && $self->_ignore_matchers->{ $env->{HTTP_HOST} }
            && $self->_ignore_matchers->{ $env->{HTTP_HOST} }
            ->( $env->{PATH_INFO} )
        )
        || (   $self->_ignore_matchers->{__global__}
            && $self->_ignore_matchers->{__global__}->( $env->{PATH_INFO} ) )
      )
    {
        return $self->_not_found_404;
    }

    # find the request file (or return error if occured)
    my $file = $self->_locate_file($path_info);
    return $file if ref $file && ref $file eq 'ARRAY';    # error occured

    # determine the content type and extension of the file
    my ( $content_type, $ext ) = $self->_determine_content_type($file);

    # determine cache control for this extension
    my ( $valid_for, $cache_control, $should_etag ) =
      $self->_determine_cache_control($ext);

    undef $should_etag if !$self->etag;

    # if this is a CSS/JS file, see if a minified representation of
    # it exists, unless the file name already has .min.css/.min.js,
    # in which case we assume it's already minified
    if (
           $self->minify
        && $file !~ m/\.min\.(css|js)$/
        && (   $content_type eq 'text/css'
            || $content_type eq 'application/javascript' )
      )
    {
        $file = $self->_minify_file( $file, $content_type );
    }

    # search for a compressed version of this file if the client supports
    # compression
    my $content_encoding;
    if ( $self->compress && $env->{HTTP_ACCEPT_ENCODING} ) {
        ( $file, $content_encoding ) =
          $self->_compress_file( $file, $env->{HTTP_ACCEPT_ENCODING} );
    }

    # okay, time to serve the file (or not, depending on whether cache
    # validations exist in the request and are fulfilled)
    return $self->_serve_file( $env, $file, $content_type, $content_encoding,
        $valid_for, $cache_control, $should_etag );
}

sub _minify_file ( $self, $file, $content_type ) {
    my $new = $file;
    $new =~ s/\.(css|js)$/.min.$1/;
    $new = $self->_filename_in_min_cache_dir($new) if $self->min_cache_dir;
    my $min = $self->_locate_file($new);

    my $try_to_minify;

    if ( $min && !ref $min ) {

        # yes, we found it, but is it still fresh? let's see
        # when was the source file modified and compare them

        # $slm is the source file's last modification date
        my $slm = ( stat( ( $self->_full_path($file) )[0] ) )[9];

        # $mlm is the minified file's last modification date
        my $mlm = ( stat( ( $self->_full_path($min) )[0] ) )[9];

        # if source file is newer than minified version,
        # we need to remove the minified version and try
        # to minify again, otherwise we can simply set the
        # minified version is the version to serve
        if ( $slm > $mlm ) {
            unlink( ( $self->_full_path($min) )[0] );
            $try_to_minify = 1;
        } else {
            return $min;
        }
    } else {

        # minified version does not exist, let's try to
        # minify ourselves
        $try_to_minify = 1;
    }

    if ($try_to_minify) {

        # can we minify ourselves?
        if (
            ( $content_type eq 'text/css' && $self->_minifiers->{css} )
            || (   $content_type eq 'application/javascript'
                && $self->_minifiers->{js} )
          )
        {
            # open the original file
            my $orig = $self->_full_path($file);
            open( my $ifh, '<:raw', $orig )
              || return $self->return_403;

            # add ->path attribute to the file handle
            Plack::Util::set_io_path( $ifh, Cwd::realpath($orig) );

            # read the file's contents into $css
            my $body;
            Plack::Util::foreach( $ifh, sub { $body .= $_[0] } );

            # minify contents
            my $min =
              $content_type eq 'text/css'
              ? CSS::Minifier::XS::minify($body)
              : JavaScript::Minifier::XS::minify($body);

            # save contents to another file
            if ($min) {
                my $out = $self->_full_path($new);
                open( my $ofh, '>:raw', $out );
                flock( $ofh, LOCK_EX );
                if ($ofh) {
                    print $ofh $min;
                    close $ofh;
                    return $new;
                }
            }
        }
    }

    return $file;
}

sub _priority ($val) {
    my ( $name, $priority ) =
      ( $val =~ m/^([^;\s]+)(?:\s*;q=(\d+(?:\.\d+)?))?$/ );
    $priority ||= 1;
    return [ $name, $priority ];
}

sub _compress_file ( $self, $file, $accept_header ) {
    my @accept_enc =
      sort { $b->[1] <=> $a->[1] }
      map { _priority($_) } split( /\s*,\s*/, $accept_header );

    for my $enc (@accept_enc) {
        next unless $self->_compressors->{ $enc->[0] };

        my ( $ext, $fnc, $err );

        if ( $enc->[0] eq 'gzip' ) {
            $ext = '.gz';
            $fnc = *IO::Compress::Gzip::gzip;
            $err = $IO::Compress::Gzip::GzipError;
        } elsif ( $enc->[0] eq 'deflate' ) {
            $ext = '.zip';
            $fnc = *IO::Compress::Deflate::deflate;
            $err = $IO::Compress::Deflate::DeflateError;
        } elsif ( $enc->[0] eq 'zstd' ) {
            $ext = '.zstd';
            $fnc = *IO::Compress::Zstd::zstd;
            $err = $IO::Compress::Zstd::ZstdError;
        } else {
            next;
        }

        my $comp = $self->_locate_file( $file . $ext );
        my $try_to_compress;
        if ( $comp && !ref $comp ) {

            # good, we found a compressed version, but is it
            # still fresh? like before let's compare its modification
            # date with the current file marked for serving

            # $slm is the source file's last modification date
            my $slm = ( stat( ( $self->_full_path($file) )[0] ) )[9];

            # $clm is compressed file's last modification date
            my $clm = ( stat( ( $self->_full_path($comp) )[0] ) )[9];

            # if source file is newer than compressed version,
            # we need to remove the compressed version and try
            # to compress again, otherwise we can simply set the
            # compressed version is the version to serve
            if ( $slm > $clm ) {
                unlink( ( $self->_full_path($comp) )[0] );
                $try_to_compress = 1;
            } else {
                return ( $comp, $enc->[0] );
            }
        } else {

            # compressed version not found, so let's try to compress
            $try_to_compress = 1;
        }

        if ($try_to_compress) {

            # we need to create a gzipped version by ourselves
            my $orig = $self->_full_path($file);
            my $out  = $self->_full_path( $file . $ext );
            if ( $fnc->( $orig, $out ) ) {
                return ( $file . $ext, $enc->[0] );
            } else {
                warn "Failed compressing ${file}: ${err}";
            }
        }
    }

    return ( $file, undef );
}

sub _locate_file ( $self, $path ) {

    # does request have a sane path?
    $path ||= '';
    return $self->_bad_request_400
      if $path =~ m/\0/;

    my ( $full, $path_arr ) = $self->_full_path($path);

    # do not allow traveling up in the directory chain
    return $self->_forbidden_403
      if grep { $_ eq '..' } @$path_arr;

    if ( -f $full ) {

        # this is a file, is it readable?
        return -r $full ? $path : $self->_forbidden_403;
    } elsif ( -d $full ) {

        # this is a directory, look for an index file, and if not exists,
        # return 403 Forbidden, as we do not do directory listings
        for my $opt ( @{ $self->index_files } ) {
            if ( -f -r File::Spec->catfile( $full, $opt ) ) {
                return File::Spec->catfile( $path, $opt );
            }
        }

        return $self->_forbidden_403;
    } else {

        # not found, return 404
        return $self->_not_found_404;
    }
}

sub _filename_in_min_cache_dir ( $self, $file ) {
    my $min_cache_dir =
      File::Spec->catfile( $self->root || ".", $self->min_cache_dir );
    mkdir $min_cache_dir if !-d $min_cache_dir;
    $file =~ s@/@%2F@g;
    my $new = File::Spec->catfile( $self->min_cache_dir, $file );
    return $new;
}

sub _determine_content_type ( $self, $file ) {

    # determine extension of the file and see if application defines
    # a content type for this extension (will even override known types)
    my ($ext) = ( $file =~ m/(\.[^.]+)$/ );
    if (   $ext
        && $self->types->{$ext}
        && $self->types->{$ext}->{content_type} )
    {
        return ( $self->types->{$ext}->{content_type}, $ext );
    }

    # okay, no specific mime defined, let's use Plack::MIME to find it
    # or fall back to text/plain
    return ( Plack::MIME->mime_type($file) || 'text/plain', $ext );
}

sub _determine_cache_control ( $self, $ext ) {
    my $valid_for     = $self->default_valid_for;
    my @cache_control = @{ $self->default_cache_control };

    # user provided extension specific settings
    if ( $ext && $self->types->{$ext} ) {
        if ( defined $self->{types}->{$ext}->{valid_for} ) {
            $valid_for = $self->types->{$ext}->{valid_for};
        }
        if ( defined $self->{types}->{$ext}->{cache_control} ) {
            @cache_control = @{ $self->types->{$ext}->{cache_control} };
        }
    }

    # unless cache control has no-store, prepend max-age to it
    my $cache = scalar( grep { $_ eq 'no-store' } @cache_control ) ? 0 : 1;
    unshift( @cache_control, 'max-age=' . $valid_for )
      if $cache;

    return ( $valid_for, \@cache_control, $cache );
}

sub _serve_file ( $self, $env, $path, $content_type, $content_encoding,
    $valid_for, $cache_control, $should_etag )
{
    # if we are serving a text file (including JSON/XML/JavaScript), append
    # character set to the content type
    $content_type .= '; charset=' . $self->charset
      if $content_type =~ m!^(text/|application/(json|xml|javascript))!;

    # get the full path of the file
    my $file = $self->_full_path($path);

    # get file statistics
    my @stat = stat $file;

    # try to find the file's etag, unless no-store is on so we don't
    # care about it
    my $etag;
    if ($should_etag) {
        if ( -f "${file}.etag" && -r "${file}.etag" ) {

            # we've found an etag file, and we can read it, but is it
            # still fresh? let's make sure its last modified date is
            # later than that of the file itself
            if ( $stat[9] > ( stat("${file}.etag") )[9] ) {

                # etag is stale, try to delete it
                unlink "${file}.etag";
            } else {

                # read the etag file
                if ( open( ETag, '<', "${file}.etag" ) ) {
                    flock( ETag, LOCK_SH );
                    $etag = <ETag>;
                    chomp($etag);
                    close ETag;
                } else {
                    warn "Can't open ${file}.etag for reading";
                }
            }
        } elsif ( -f "${file}.etag" ) {
            warn "Can't open ${file}.etag for reading";
        }
    }

    # did the client send cache validations?
    if ( $env->{HTTP_IF_MODIFIED_SINCE} ) {

        # okay, client wants to see if resource was modified. IE sends wrong
        # formatted value (i.e. "Thu, 03 Dec 2009 01:46:32 GMT; length=17936")
        # - taken from Plack::Middleware::ConditionalGET
        $env->{HTTP_IF_MODIFIED_SINCE} =~ s/;.*$//;
        my $since = HTTP::Date::str2time( $env->{HTTP_IF_MODIFIED_SINCE} );

        # if file was modified on or before $since, return 304 Not Modified
        return $self->_not_modified_304
          if $stat[9] <= $since;
    }

    if (   $etag
        && $env->{HTTP_IF_NONE_MATCH}
        && $etag eq $env->{HTTP_IF_NONE_MATCH} )
    {
        return $self->_not_modified_304;
    }

    # okay, we need to serve the file
    # open it first
    open my $fh, '<:raw', $file
      || return $self->return_403;

    # add ->path attribute to the file handle
    Plack::Util::set_io_path( $fh, Cwd::realpath($file) );

    # did we find an ETag file earlier? if not, let's create one (unless
    # we shouldn't due to no-store)
    if ( $should_etag && !$etag ) {

        # following code based on Plack::Middleware::ETag by Franck Cuny
        # P::M::ETag creates weak ETag if it sees the resource was
        # modified less than a second before the request. It seems
        # like it does that because there's a good chance the resource
        # will be modified again soon afterwards. I'm not gonna do
        # that because if MCCS minified/compressed by itself, it will
        # pretty much always mean the ETag will be created less than a
        # second after the file was modified, and I know it's not gonna
        # be modified again soon, so I see no reason to do that here

        # add inode to etag
        $etag .= join( '-',
            sprintf( "%x", $stat[2] ),
            sprintf( "%x", $stat[9] ),
            sprintf( "%x", $stat[7] ) );

        # save etag to a file
        if ( open( ETag, '>', "${file}.etag" ) ) {
            flock( ETag, LOCK_EX );
            print ETag $etag;
            close ETag;
        } else {
            undef $etag;
            warn "Can't open ETag file ${file}.etag for writing";
        }
    }

    # set response headers
    my $headers = [];
    push( @$headers, 'Content-Encoding' => $content_encoding )
      if $content_encoding;
    push( @$headers, 'Content-Length' => $stat[7] );
    push( @$headers, 'Content-Type'   => $content_type );
    push( @$headers, 'Last-Modified'  => HTTP::Date::time2str( $stat[9] ) );
    push( @$headers,
        'Expires' => $valid_for >= 0
        ? HTTP::Date::time2str( $stat[9] + $valid_for )
        : HTTP::Date::time2str(0) );
    push( @$headers, 'Cache-Control' => join( ', ', @$cache_control ) );
    push( @$headers, 'ETag'          => $etag ) if $etag;
    push( @$headers, 'Vary'          => 'Accept-Encoding' );

    # respond
    return [ 200, $headers, $fh ];
}

sub _full_path ( $self, $path ) {
    my $docroot = $self->root || '.';

    # break path into chain
    my @path = split( '/', $path );
    if (@path) {
        shift @path if $path[0] eq '';
    } else {
        @path = ('.');
    }

    my $full = File::Spec->catfile( $docroot, @path );
    return wantarray ? ( $full, \@path ) : $full;
}

sub _load_ignore_files ($self) {
    $self->{_ignore_matchers}->{'__global__'} =
      $self->_load_ignore_file( $self->ignore_file, undef );

    if ( $self->vhost_mode ) {

        # look for ignore files in all subdirectories
        opendir( my $dir, $self->root );
        my @dirs =
          grep { !/^\.\.?$/ && -d File::Spec->catfile( $self->root, $_ ) }
          readdir $dir;
        closedir $dir;

        for my $dir (@dirs) {
            $self->{_ignore_matchers}->{$dir} =
              $self->_load_ignore_file( $self->ignore_file, $dir );
        }
    }
}

sub _load_ignore_file ( $self, $path, $host ) {
    my $fullpath =
        $host
      ? $self->_full_path( File::Spec->catfile( $host, $path ) )
      : $self->_full_path($path);

    if ( !-f $fullpath ) {
        return;
    }

    open( my $file, '<', $fullpath );
    my @rules;
    while ( my $line = <$file> ) {
        chomp($line);
        push( @rules, $line );
    }
    close $file;

    # add the ignore file itself to the rules
    push( @rules, $path );

    return build_gitignore_matcher( \@rules );
}

sub _not_modified_304 {
    [ 304, [], [] ];
}

sub _bad_request_400 {
    [
        400, [ 'Content-Type' => 'text/plain', 'Content-Length' => 11 ],
        ['Bad Request']
    ];
}

sub _forbidden_403 {
    [
        403, [ 'Content-Type' => 'text/plain', 'Content-Length' => 9 ],
        ['Forbidden']
    ];
}

sub _not_found_404 {
    [
        404, [ 'Content-Type' => 'text/plain', 'Content-Length' => 9 ],
        ['Not Found']
    ];
}

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-Plack-App-MCCS@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-App-MCCS>.

=head1 SEE ALSO

L<Plack::Middleware::MCCS>, L<Plack::Middleware::Static>, L<Plack::App::File>,
L<Plack::Builder>.

=head1 AUTHOR

Ido Perlmuter <ido@ido50.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2023, Ido Perlmuter C<< ido@ido50.net >>.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
__END__
