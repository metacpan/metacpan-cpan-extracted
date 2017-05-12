use strict;
use warnings;

package Mojolicious::Quick;
$Mojolicious::Quick::VERSION = '0.002';
use Carp;
use Mojo::Base 'Mojolicious';

# ABSTRACT: A quick way of generating a simple Mojolicious app.


has rewrite_url => 1;

my @HTTP_VERBS = qw/GET POST PUT DELETE PATCH OPTIONS/;

sub new {
    my $class  = shift;
    my $routes = shift;

    if ( $routes && ref $routes ne 'ARRAY' ) {
        unshift @_, $routes;
    }
    my $self = $class->SUPER::new(@_);

    while ( my $path = shift @{$routes} ) {
        my $action = shift @{$routes};
        if ( grep { $path eq $_ } @HTTP_VERBS ) {
            my $verb = lc $path;

            $path = $action;
            if ( ref $path ) {
                my @paths;
                eval {
                    @paths = @{$path};
                    1;
                } or do {
                    my $reftype = ref $path;
                    croak qq{Object of type $reftype cannot be coerced into an array};
                };
                while ( my $path = shift @paths ) {
                    $action = shift @paths;
                    $self->routes->$verb( $path, $action );
                }
            }
            else {
                $action = shift @{$routes};
                $self->routes->$verb( $path => $action );
            }
        }
        else {
            $self->routes->any( $path => $action );
        }
    }

    $self->ua->on(
        start => sub {
            my ( $ua, $tx ) = @_;
            $ua->emit( original_request => $tx->req );
            if ( $self->rewrite_url ) {
                $tx->req->url->host('')->scheme('')->port( $ua->server->url->port );
            }
        }
    );

    return $self;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Quick - A quick way of generating a simple Mojolicious app.

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Mojolicious::Quick;

    # Specify routes for all HTTP verbs
    my $app = Mojolicious::Quick->new(
        [   '/thing/:id' => sub {
                my $c  = shift;
                my $id = $c->stash('id');
                $c->render( text => qq{Thing $id} );
            },
            '/other/thing/:id' => sub {
                my $c  = shift;
                my $id = $c->stash('id');
                $c->render( text => qq{Other thing $id} );
            },
            '/another/thing/:id' => sub {
                my $c  = shift;
                my $id = $c->stash('id');
                $c->render( text => qq{Another thing $id} );
            },
        ]
    );

    # Specify different routes for different HTTP verbs
    my $app = Mojolicious::Quick->new(
            GET => [
                '/thing/:id' => sub {
                    my $c  = shift;
                    my $id = $c->stash('id');
                    $c->render( text => qq{Get thing $id} );
                },
                '/other/thing/:id' => sub {
                    my $id = $c->stash('id');
                    $c->render( text => qq{Get other thing $id} );
                }
            ],
            POST => [
                '/thing/:id' => sub {
                    my $c  = shift;
                    my $id = $c->stash('id');
                    $c->render( text => qq{Post thing $id} );
                },
            ],
            PUT => [
                '/thing/:id' => sub {
                    my $c  = shift;
                    my $id = $c->stash('id');
                    $c->render( text => qq{Put thing $id} );
                },
            ],
            PATCH => [
                '/thing/:id' => sub {
                    my $c  = shift;
                    my $id = $c->stash('id');
                    $c->render( text => qq{Patch thing $id} );
                },
            ],
            OPTIONS => [
                '/thing/:id' => sub {
                    my $c  = shift;
                    my $id = $c->stash('id');
                    $c->render( text => qq{Options thing $id} );
                },
            ],
            DELETE => [
                '/thing/:id' => sub {
                    my $c  = shift;
                    my $id = $c->stash('id');
                    $c->render( text => qq{Delete thing $id} );
                },
            ],
        }
    );

    my $ua = $app->ua;
    my $tx = $ua->get('/thing/23'); # Returns body "Get thing 23"

=head1 ATTRIBUTES

=head2 rewrite_url

Set to "true" by default. When this is set, the internal user agent (UA) will rewrite URLs 
internally to originate from localhost. The original request will be available in the 
'original_request' event emitted by the UA.

=head2 ua

Instance of L<Mojo::UserAgent>.  Note that this comes from L<Mojo>; it is noted here to remind the 
user that they have it available to them. You can also use this to attach your own instance of 
Mojo::UserAgent if need be.

=head1 NOTES

=head2 USE CASE, or "What's the point?"

In developing a client that interfaces with a Web service, you might not always have access to said
Web service. Perhaps you don't have authentication credentials. Perhaps the service is still in 
development.  For whatever reason, if you need to mock up a quick and dirty Web application that you 
can test against, this will allow you to do it.

=head2 It's still Mojo under the hood.

There is nothing in this package you can't do with regular L<Mojolicious> or L<Mojolicious::Lite>.
This package simply makes that easier. For example, if you wanted a Mojolicious app in a single
scalar:

    package MyApp { use Mojolicious::Lite; }
    my $app = MyApp::App;
    $app->routes->get(
        '/foo/bar' => sub {
            # ...
        }
    );

And if you wanted to to the URL rewrite business:

    my $app = Mojolicious::new();

    $app->ua->on(
        start => sub {
            my ( $ua, $tx ) = @_;
            $tx->req->url->host('')->scheme('')->port( $ua->server->url->port );
        }
    );

=head1 EVENTS

=head2 original_request

    my $app = Mojolicious::Quick->new(
        # ...
    );
    
    $app->ua->on('original_request' => sub { 
        my $req = shift;  # instance of Mojo::Message::Request
        my $original_url = $req->url;
        say "Original URL is $original_url";
    });

An event that stores the original request.  This event is always emitted, regardless of the value
of L</rewrite_url>

=head1 AUTHOR

Kit Peters <popefelix@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Broadbean Technology.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
