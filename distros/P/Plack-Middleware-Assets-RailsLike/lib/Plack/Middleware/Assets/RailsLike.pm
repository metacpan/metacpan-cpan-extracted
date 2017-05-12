package Plack::Middleware::Assets::RailsLike;

use 5.010_001;
use strict;
use warnings;
use parent 'Plack::Middleware';
use Cache::NullCache;
use Cache::MemoryCache;
use Carp         ();
use Digest::SHA1 ();
use Errno        ();
use File::Basename;
use File::Slurp;
use File::Spec::Functions qw(catdir catfile canonpath);
use HTTP::Date ();
use Plack::Util::Accessor qw(path root search_path expires cache minify);
use Plack::Middleware::Assets::RailsLike::Compiler;

our $VERSION = "0.13";

our $EXPIRES_NEVER = $Cache::Cache::EXPIRES_NEVER;
our $EXPIRES_NOW   = $Cache::Cache::EXPIRES_NOW;

# copy from Cache::BaseCache
my %_expiration_units = (
    map( ( $_, 1 ),                  qw(s second seconds sec) ),
    map( ( $_, 60 ),                 qw(m minute minutes min) ),
    map( ( $_, 60 * 60 ),            qw(h hour hours) ),
    map( ( $_, 60 * 60 * 24 ),       qw(d day days) ),
    map( ( $_, 60 * 60 * 24 * 7 ),   qw(w week weeks) ),
    map( ( $_, 60 * 60 * 24 * 30 ),  qw(M month months) ),
    map( ( $_, 60 * 60 * 24 * 365 ), qw(y year years) )
);

sub prepare_app {
    my $self = shift;

    # Set default values for options
    $self->{path}        ||= qr{^/assets};
    $self->{root}        ||= '.';
    $self->{search_path} ||= [ catdir( $self->{root}, 'assets' ) ];
    $self->{expires}     ||= '3 days';

    if ( $self->{cache} ) {
        $self->{_max_age} = $self->_max_age;
    }
    elsif ( $ENV{PLACK_ENV} and $ENV{PLACK_ENV} eq 'development' ) {

        # disable cache
        $self->{cache}    = Cache::NullCache->new;
        $self->{_max_age} = 0;
    }
    else {
        $self->{cache} = Cache::MemoryCache->new(
            {
                namespace           => __PACKAGE__,
                default_expires_in  => $self->{expires},
                auto_purge_interval => '1 day',
                auto_purge_on_set   => 1,
                auto_purge_on_get   => 1
            }
        );
        $self->{_max_age} = $self->_max_age;
    }

    $self->{minify} //= 1;

    $self->{_compiler} = Plack::Middleware::Assets::RailsLike::Compiler->new(
        minify      => $self->{minify},
        search_path => $self->{search_path},
    );
}

sub call {
    my ( $self, $env ) = @_;

    my $path_info = $env->{PATH_INFO};
    if ( $path_info =~ $self->path ) {
        my $real_path = canonpath( catfile( $self->root, $path_info ) );
        my ( $filename, $dirs, $suffix )
            = fileparse( $real_path, qr/\.[^.]*/ );
        my $type = $suffix eq '.js' ? 'js' : 'css';

        my $content;
        {
            local $@;
            eval {
                $content
                    = $self->_build_content( $real_path, $filename, $dirs,
                    $suffix, $type );
            };
            if ($@) {
                warn $@;
                return $self->_500;
            }
        }
        return $self->_404 unless $content;

        my $etag = Digest::SHA1::sha1_hex($content);
        if ( $env->{'HTTP_IF_NONE_MATCH'} || '' eq $etag ) {
            return $self->_304;
        }
        else {
            return $self->_build_response( $content, $type, $etag );
        }
    }
    else {
        return $self->app->($env);
    }
}

sub _build_content {
    my $self = shift;
    my ( $real_path, $filename, $dirs, $suffix, $type ) = @_;
    my ( $base, $version ) = $filename =~ /^(.+)-([^\-]+)$/;

    my $content = $self->cache->get($real_path);
    return $content if $content;

    my ( @list, $pre_compiled );
    if ($version) {
        @list = ( $real_path, catfile( $dirs, "$base$suffix" ) );
        $pre_compiled = 1;
    }
    else {
        @list         = ($real_path);
        $pre_compiled = 0;
    }

    for my $file (@list) {
        my $manifest;
        read_file( $file, buf_ref => \$manifest, err_mode => sub { } );
        if ( $! && $! == Errno::ENOENT ) {
            $pre_compiled = 0;
            next;
        }
        elsif ($!) {
            die "read_file '$file' failed - $!";
        }

        if ($pre_compiled) {
            $content = $manifest;
        }
        else {
            $content = $self->{_compiler}->compile(
                manifest => $manifest,
                type     => $type
            );
        }

        # filename with versioning as a key
        $self->cache->set( $real_path, $content, $self->{_max_age} )
          if $self->{_max_age} > 0;
        last;
    }
    return $content;
}

sub _build_response {
    my $self = shift;
    my ( $content, $type, $etag ) = @_;

    # build headers
    my $content_type = $type eq 'js' ? 'application/javascript' : 'text/css';
    my $max_age      = $self->{_max_age};
    my $expires      = time + $max_age;

    if ( $max_age > 0 ) {
        return [
            200,
            [
                'Content-Type'   => $content_type,
                'Content-Length' => length($content),
                'Cache-Control'  => sprintf( 'max-age=%d', $max_age ),
                'Expires'        => HTTP::Date::time2str($expires),
                'Etag'           => $etag,
            ],
            [$content]
        ];
    }
    else {
        return [
            200,
            [
                'Content-Type'   => $content_type,
                'Content-Length' => length($content),
                'Cache-Control'  => 'no-store',
            ],
            [$content]
        ];
    }
}

sub _max_age {
    my $self    = shift;
    my $max_age = 0;
    if ( $self->expires eq $EXPIRES_NEVER ) {

        # See http://www.w3.org/Protocols/rfc2616/rfc2616.txt 14.21 Expires
        $max_age = $_expiration_units{'year'};
    }
    elsif ( $self->expires eq $EXPIRES_NOW ) {
        $max_age = 0;
    }
    else {
        $max_age = $self->_expires_in_seconds;
    }
    return $max_age;
}

sub _expires_in_seconds {
    my $self    = shift;
    my $expires = $self->expires;

    my ( $n, $unit ) = $expires =~ /^\s*(\d+)\s*(\w+)\s*$/;
    if ( $n && $unit && ( my $secs = $_expiration_units{$unit} ) ) {
        return $n * $secs;
    }
    elsif ( $expires =~ /^\s*(\d+)\s*$/ ) {
        return $expires;
    }
    else {
        Carp::carp "Invalid expiration time '$expires'";
        return 0;
    }
}

sub _304 {
    my $self = shift;
    $self->_response( 304, 'Not Modified' );
}

sub _404 {
    my $self = shift;
    $self->_response( 404, 'Not Found' );
}

sub _500 {
    my $self = shift;
    $self->_response( 500, 'Internal Server Error' );
}

sub _response {
    my $self = shift;
    my ( $code, $content ) = @_;
    return [
        $code,
        [   'Content-Type'   => 'text/plain',
            'Content-Length' => length($content)
        ],
        [$content]
    ];
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Assets::RailsLike - Bundle and minify JavaScript and CSS files

=head1 SYNOPSIS

    use strict;
    use warnings;
    use MyApp;
    use Plack::Builder;

    my $app = MyApp->new->to_app;
    builder {
        enable 'Assets::RailsLike', root => './htdocs';
        $app;
    };

=head1 WARNING

B<This module is under development and considered BETA quality.>

=head1 DESCRIPTION

Plack::Middleware::Assets::RailsLike is a middleware to bundle and minify
JavaScript and CSS (included Sass and LESS) files like Ruby on Rails Asset
Pipeline.

At first, you create a manifest file. The Manifest file is a list of JavaScript
and CSS files you want to bundle. You can also use Sass and LESS as css files.
The Manifest syntax is same as Rails Asset Pipeline, but only support
C<require> command.

    > vim ./htdocs/assets/main-page.js
    > cat ./htdocs/assets/main-page.js
    //= require jquery
    //= require myapp


Next, write URLs of manifest file to your html. This middleware supports
versioning. So you can add version string in between its file basename and
suffix.

    <- $basename-$version.$suffix ->
    <script type="text/javascript" src="/assets/main-page-v2013060701.js">

If manifest files were requested, bundle files in manifest file and serve it or
serve bundled data from cache. In this case, find jquery.js and myapp.js from
search path (default search path is C<$root>/assets). This middleware return
HTTP response with C<Cache-Control>, C<Expires> and C<Etag>. C<Cache-Control>
and C<Expires> are computed from the C<expires> option. C<Etag> is computed
from bundled content.

=head1 CONFIGURATIONS

=over 4

=item root

Document root to find manifest files to serve.

Default value is current directory('.').

=item path

The URL pattern (regular expression) for matching.

Default value is C<qr{^/assets}>.

=item search_path

Paths to find javascript and css files.

Default value is C<[qw($root/assets)]>.

=item minify

Minify javascript and css files if true.

Default value is C<1>.

=item cache

Store concatenated data in memory by default using L<Cache::MemoryCache>. The
C<cache> option must be a object implemented C<get> and C<set> methods. For
example, L<Cache::Memcached::Fast>. If C<$ENV{PLACK_ENV} eq "development"> and
you didn't pass a cache object, cache is disabled.

Default is a L<Cache::MemoryCache> Object.

    Cache::MemoryCache->new({
        namespace           => "Plack::Middleware::Assets::RailsLike",
        default_expires_in  => $expires
        auto_purge_interval => '1 day',
        auto_purge_on_set   => 1,
        auto_purge_on_get   => 1
    })

=item expires

Expiration of the cache and Cache-Control, Expires headers in HTTP response.
The format of This option is same as default_expires_in option of
L<Cache::Cache>. See L<Cache::Cache> for more details.

Default is C<'3 days'>.

=back

=head1 PRECOMPILE

This distribution includes L<assets-railslike-precompiler.pl>. This script can
pre-compile manifest files. See perldoc L<assets-railslike-precompiler.pl> for
more details.

I strongly recommend using pre-compiled files with
L<Plack::Middleware::Static> in the production environment.

=head1 MOTIVATION

I want a middleware has futures below.

    1. Concat JavaScript and CSS
    2. Minify contents
    3. Cache a compiled data
    4. Version string in filename
    5. Support Sass and LESS files
    6. Less configuration
    7. Pre-compile

L<Plack::Middleware::StaticShared> is good choice for me. But it needs to write
definitions for each resource types. And its URL format is a bit strange.

=head1 SEE ALSO

L<Plack::Middleware::StaticShared>

L<Plack::Middleware::Assets>

L<Plack::App::MCCS>

L<Plack::Middleware::Static::Combine>

L<Plack::Middleware::Static::Minifier>

L<Plack::Middleware::Compile>

L<Plack::Middleware::JSConcat>

L<Catalyst::Plugin::Assets>

=head1 DEPENDENCIES

L<Plack>

L<Cache::Cache>

L<File::Slurp>

L<JavaScript::Minifier::XS>

L<CSS::Minifier::XS>

L<Digest::SHA1>

L<HTTP::Date>

L<Text::Sass>

L<CSS::LESSp>

=head1 LICENSE

Copyright (C) 2013 Yoshihiro Sasaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yoshihiro Sasaki E<lt>ysasaki@cpan.orgE<gt>

=cut
