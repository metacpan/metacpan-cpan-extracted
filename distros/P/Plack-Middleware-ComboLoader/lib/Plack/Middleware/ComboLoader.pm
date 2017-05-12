package Plack::Middleware::ComboLoader;
{
  $Plack::Middleware::ComboLoader::VERSION = '0.04';
}
use strict;
use warnings;

use parent qw(Plack::Middleware);

use Carp 'carp';

use Plack::Request;

use Path::Class;
use Plack::MIME;
use Try::Tiny;

use URI::Escape 'uri_escape';
use HTTP::Date 'time2str';

# ABSTRACT: Handle combination loading and processing of on-disk resources.

__PACKAGE__->mk_accessors(qw( roots save expires max_age));


sub call {
    my ( $self, $env ) = @_;

    my $roots = $self->roots || {};
    unless ( ref($roots) eq 'HASH' ) {
        carp "Invalid root configuration, roots must be a hash ref of names to paths\n";
    }

    my $path_info = $env->{PATH_INFO};
    $path_info =~ s/^\///;

    my $req = Plack::Request->new( $env );
    my $res = $req->new_response;

    if ( exists $roots->{$path_info} or exists $roots->{"/$path_info"} ) {
        my $path = $roots->{$path_info} || $roots->{"/$path_info"};
        my $config = {};
        if ( ref $path eq 'HASH' ) {
            $config = $path;
        } else {
            $config->{path} = $path;
        }

        my $dir = Path::Class::Dir->new($config->{path});
        unless ( -d $dir ) {
            $res->status(500);
            $res->body("Invalid root directory for `/$path_info`: $dir does not exist");
            return $res->finalize;
        }

        my @resources = split('&', $env->{QUERY_STRING});
        $res->status(200);

        my $content_type = 'plain/text';
        my $max_age      = defined $self->max_age ? $self->max_age : 315360000;

        if ( $self->save ) {
            my $save_dir = Path::Class::Dir->new($self->save)->subdir($path_info);
            my $f = $save_dir->file( uri_escape($env->{QUERY_STRING}) );
            my $stat = $f->stat;
            my $expiry = $self->expires || 86400;
            if ( $stat && $stat->mtime + $expiry > time ) {
                # Not sure what the best way to do this is. Looking at
                # Plack::App::File
                my ( $content_type, @buffer ) = $f->slurp;
                $res->header('Last-Modified'  => time2str( $stat->mtime ));
                $res->header('X-Generated-On' => time2str( $stat->mtime ));

                $res->header('Age' => 0);
                $res->header('Cache-Control' => "public, max-age=$max_age");
                $res->header('Expires' => time2str( time + $max_age ) );

                $res->content_type($content_type);
                $res->content(join("", @buffer));
                return $res->finalize;
            }
        }

        my $buffer        = '';
        my $last_modified = 0;
        my %seen_types    = ();

        foreach my $resource ( @resources ) {
            my $f = $dir->file($resource);
            my $stat = $f->stat;
            unless ( defined $stat ) {
                $res->status(400);
                $res->content("Invalid resource requested: `$resource` is not available.");
                return $res->finalize;
            }

            $seen_types{ Plack::MIME->mime_type($f->basename) || 'text/plain' } = 1;
            # Set the last modified to the most recent file.
            $last_modified = $stat->mtime if $stat->mtime > $last_modified;

            if ( exists $config->{processor} ) {
                local $_ = $f;
                try { $buffer .= $config->{processor}->($f); }
                catch {
                    $res->status(500);
                    $res->body("Processing failed for `$resource`: $_");
                    return $res->finalize;
                };
            } else {
                $buffer .= $f->slurp;
            }
        }
        if ( $self->save ) {
            my $save_dir = Path::Class::Dir->new($self->save)->subdir($path_info);
            $save_dir->mkpath;
            my $f = $save_dir->file( uri_escape($env->{QUERY_STRING}) );
            my $fh = $f->openw;
            print $fh "$content_type\n";
            print $fh $buffer;
            $fh->close;
        }

        # We only encountered one content-type, rejoice, for we can set one
        # sensibly!
        if ( scalar keys %seen_types == 1 ) {
            ( $content_type ) = keys %seen_types;
        }

        $res->content_type($content_type);

        $res->header('Last-Modified' => time2str( $last_modified ) );
        $res->header('Age' => 0);
        $res->header('Cache-Control' => "public, max-age=$max_age");
        $res->header('Expires' => time2str( time + $max_age ) );

        $res->content($buffer);
        return $res->finalize;
    }

    $self->app->($env);
}

1;

__END__
=pod

=head1 NAME

Plack::Middleware::ComboLoader - Handle combination loading and processing of on-disk resources.

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use Plack::Builder;

    # Whatever your Plack app may be, though using this with
    # Plack::App::File works very well!
    my $app = [ 200, [ 'Content-Type' => 'plain/text' ], 'Hello' ];
    builder {
        enable "ComboLoader",
            # Defaults to this, goes out 10 years. 
            max_age => 315360000,
            roots => {
                'yui3'         => 'yui3/',
                'yui3-gallery' => 'yui3-gallery/',
                'our-gallery'  => 'our-gallery/',
                # Or, if you want to run each file through something:
                '/static/css' => {
                    path      => 'static/css',
                    processor => sub {
                        # $_ isa Path::Class::File object
                        # It is much, much better to minify as a build process
                        # and not on demand.
                        CSS::Minifier::minify( input => $_->slurp );
                        # This method returns a *string*
                    }
                }
            },
            # Optional parameter to save generated files to this path:
            # If the file is there and it's not too old, it gets served.
            # If it is too old (the expires below), it will be regenerated.
            save => 'static/combined',
            expires => 86400, # Keep files around for a day.
        $app;
    };

=head1 DESCRIPTION

This is (another) combination loader for static resources. This is designed to
operate with the YUI3 Loader Service.

You can specify multiple points, and if all files are of the same type it sets
the mime-type and all proper caching headers for the browser.

The incoming requests will look like:

    http://my.cdn.com/rootName?3.4.1/build/module/module.js&3.4.1/build/module2/module2.js

The rootName specifies the path on disk, and each query arg is a file under the
path.

=head1 PROCESSING FILES

I highly recommend doing minifying and building prior to any serving. This way
files stay on disk, unmodified and perform better.  If, however, you want to
do any processing (like compiling templates into JavaScript, a la Handlebars)
you can do that.

Use the C<processor> option, you can munge your files however you wish.

The sub is passed in a L<Path::Class::File> object, and should return a byte
encoded string. Plack will require it to be byte encoded, and you will have
incorrect results if you do not encode accordingly.

Whatever return value is appended to the output buffer and sent to the client.

=head1 CONFIGURATION

There are the following configuration settings:

=over

=item roots

The only required parameter for anything to actually happen. This is a list
of roots and the directories in which to look at files.

    roots => {
        'yui3' => '/var/www/builds/yui3',
        'yui2' => '/var/www/builds/yui2',
    }

That configuration would create combo roots for yui3 and yui2, handling links
as expected.

=item max_age

Specify an alternate max-age header and Expires, this defaults to 10 years out.

=item save

Should we save the resulting file to disk? Probably not, but sometimes a bad
idea can be good. It's better to instead use a caching middleware or frontend.

If the item exists on disk, and is not too old (see expires option below), this
will serve the file directly.

The intention is not for performance really, but for pregenerating files that
may take a long time or external information (and a reasonable fallback).

=item expires

Specify how long a file on disk is valid before regenerating. If you are
pregenerating files, make sure this is set far enough in the future they never
grow stale.

=back

=head1 AUTHOR

J. Shirley <j@shirley.im>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

