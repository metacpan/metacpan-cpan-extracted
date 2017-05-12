package PGXN::Site::Router;

use 5.10.0;
use utf8;
use PGXN::Site::Controller;
use Router::Resource;
use Plack::Builder;
use Plack::App::File;
our $VERSION = v0.10.3;

sub app {
    my $class = shift;
    my %p = @_;
    my $controller = PGXN::Site::Controller->new(@_);
    (my $ui = __FILE__) =~ s{Router[.]pm$}{ui};
    my $files      = Plack::App::File->new(root => $ui)->to_app;
    my $router     = router {
        missing { $controller->missing(@_) };

        # /
        resource qr{^/(?:index[.]html)?$} => sub {
            GET { $controller->home(@_) }
        };

        # /search
        resource qr{^/search$} => sub {
            GET {
                $controller->search(shift);
            }
        };

        # /dist/{dist}
        # /dist/{dist}/{version}
        resource qr{/dist/([^/]+)(?:/(\d[^/]+))?/?$} => sub {
            GET {
                my ($env, $args) = @_;
                $controller->distribution($env, @{ $args->{splat} } );
            };
        };

        # /dist/{dist}/{path}
        # /dist/{dist}/{version}/{path}
        resource qr{/dist/([^/]+)(?:/(\d[^/]+))?/(.+)[.]html$} => sub {
            GET {
                my ($env, $args) = @_;
                $controller->document($env, @{ $args->{splat} } );
            };
        };

        # /user/{user}/
        resource qr{/user/([^/]+)/?$} => sub {
            GET {
                my ($env, $args) = @_;
                $controller->user($env, @{ $args->{splat} } );
            };
        };

        # /tag/{tag}/
        resource qr{/tag/([^/]+)/?$} => sub {
            GET {
                my ($env, $args) = @_;
                $controller->tag($env, @{ $args->{splat} } );
            };
        };

        # /extension/{extension}/
        resource qr{/extension/([^/]+)/?$} => sub {
            GET {
                my ($env, $args) = @_;
                $controller->extension($env, @{ $args->{splat} } );
            };
        };

        # /feedback
        resource qr{^/feedback/?$} => sub {
            GET { $controller->feedback(shift) };
        };

        # /art
        resource qr{^/art/?$} => sub {
            GET { $controller->art(shift) };
        };

        # /about
        resource qr{^/about/?$} => sub {
            GET { $controller->about(shift) };
        };

        # /users/
        resource qr{/users/?$} => sub {
            GET { $controller->users(shift) };
        };

        # /recent
        resource qr{^/recent/?$} => sub {
            GET { $controller->recent(shift) };
        };

        # /donors
        resource qr{^/donors/?$} => sub {
            GET { $controller->donors(shift) };
        };

        # /faq
        resource qr{^/faq/?$} => sub {
            GET { $controller->faq(shift) };
        };

        # /mirroring
        resource qr{^/mirroring/?$} => sub {
            GET { $controller->mirroring(shift) };
        };

        # /meta/spec.txt.
        resource '/meta/spec.txt' => sub {
            GET { $controller->spec(shift, 'txt') };
        };

        # /spec
        resource qr{^/spec/?$} => sub {
            GET { $controller->spec(shift, 'html') };
        };

        # /error (500 error responder).
        resource '/error' => sub {
            GET { $controller->server_error(@_) };
        };

        # Handle legacy URLs.
        my %url_for = (
            contact      => '/feedback/',
            contributors => '/donors/',
            mirroring    => '/mirroring/',
            faq          => '/faq/',
            'meta/spec'  => '/spec/',
        );

        resource qr{^/(cont(?:ributors|act)|mirroring|faq|meta/spec)[.]html$} => sub {
            GET {
                my ($env, $args) = @_;
                my $res = Plack::Response->new;
                $res->redirect($url_for{ $args->{splat}[0] }, 301);
                $res->finalize;
            };
        };
    };

    builder {
        enable 'ErrorDocument', 500, '/error', subrequest => 1;
        enable 'HTTPExceptions';
        enable 'StackTrace', no_print_errors => 1;
        enable 'ReverseProxy' if $p{reverse_proxy};
        mount '/'   => builder { sub { $router->dispatch(shift) } };
        mount '/ui' => $files;
    }
}

1;

=head1 Name

PGXN::Site::Router - The PGXN::Site request router.

=head1 Synopsis

  # In app.pgsi
  use PGXN::Site::Router;
  PGXN::Site::Router->app;

=head1 Description

This class defines the HTTP request routing table used by PGXN::Site. Unless
you're modifying the PGXN::Site routes and controllers, you won't have to
worry about it. Just know that this is the class that Plack uses to fire up
the app.

=head1 Interface

=head2 Class Methods

=head3 C<app>

  PGXN::Site->app;

Returns the PGXN::Site Plack app. See L<pgxn_site_server> for an example
usage. It's not much to look at. But Plack uses the returned code reference to
power the application.

=head1 Author

David E. Wheeler <david.wheeler@pgexperts.com>

=head1 Copyright and License

Copyright (c) 2010-2013 David E. Wheeler.

This module is free software; you can redistribute it and/or modify it under
the L<PostgreSQL License|http://www.opensource.org/licenses/postgresql>.

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose, without fee, and without a written agreement is
hereby granted, provided that the above copyright notice and this paragraph
and the following two paragraphs appear in all copies.

In no event shall David E. Wheeler be liable to any party for direct,
indirect, special, incidental, or consequential damages, including lost
profits, arising out of the use of this software and its documentation, even
if David E. Wheeler has been advised of the possibility of such damage.

David E. Wheeler specifically disclaims any warranties, including, but not
limited to, the implied warranties of merchantability and fitness for a
particular purpose. The software provided hereunder is on an "as is" basis,
and David E. Wheeler has no obligations to provide maintenance, support,
updates, enhancements, or modifications.

=cut
