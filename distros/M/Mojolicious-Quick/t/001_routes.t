use strict;
use warnings;

use String::Random qw/random_string/;
use Test::Most;
use Test::Mojo;
use Mojolicious::Quick;

subtest 'simple routes' => sub {
    my $app = Mojolicious::Quick->new(
        [   '/thing/:id' => sub {
                my $c  = shift;
                my $id = $c->stash('id');
                $c->render( text => qq{Thing $id} );
            }
        ]
    );
    my $t = Test::Mojo->new($app);
    for my $verb (qw/get post put patch/) {
        my $method = sprintf '%s_ok', $verb;
        $t->$method('/thing/23')->status_is(200)->content_is('Thing 23');
    }
};

subtest 'route by HTTP verb' => sub {
    my $app = Mojolicious::Quick->new(
        [   GET => '/thing/:id' => sub {
                my $c  = shift;
                my $id = $c->stash('id');
                $c->render( json => { 'id' => $id, 'method' => 'get' } );
            },
            POST => '/thing/:id' => sub {
                my $c       = shift;
                my $id      = $c->stash('id');
                my $whatsis = $c->param('whatsis');
                $c->render( json => { 'id' => $id, 'whatsis' => $whatsis, 'method' => 'post' } );
            },
            PUT => '/thing/:id' => sub {
                my $c       = shift;
                my $id      = $c->stash('id');
                my $whatsis = $c->param('whatsis');
                $c->render( json => { 'id' => $id, 'whatsis' => $whatsis, 'method' => 'put' } );
            },
            PATCH => '/thing/:id' => sub {
                my $c       = shift;
                my $id      = $c->stash('id');
                my $whatsis = $c->param('whatsis');
                $c->render( json => { 'id' => $id, 'whatsis' => $whatsis, 'method' => 'patch' } );
            },
            OPTIONS => '/thing/:id' => sub {
                my $c       = shift;
                my $id      = $c->stash('id');
                my $whatsis = $c->param('whatsis');
                $c->render( json => { 'id' => $id, 'whatsis' => $whatsis, 'method' => 'options' } );
            },
            DELETE => '/thing/:id' => sub {
                my $c       = shift;
                my $id      = $c->stash('id');
                my $whatsis = $c->param('whatsis');
                $c->render( json => { 'id' => $id, 'whatsis' => $whatsis, 'method' => 'delete' } );
            },
        ]
    );
    my $t = Test::Mojo->new($app);
    $t->get_ok('/thing/23')->status_is(200)->json_is({'id' => 23, method => 'get'});
    for my $verb (qw/post put patch options delete/) {
        my $method = sprintf '%s_ok', $verb;
        my $whatsis = random_string('ccc');
        $t->$method('/thing/23' => form => { whatsis => $whatsis } )->status_is(200)->json_is( { id => 23, method => $verb, whatsis => $whatsis } );
    }
};

subtest 'URL rewrite' => sub {
    my $app = Mojolicious::Quick->new(
        [   '/thing/:id' => sub {
                my $c  = shift;
                my $id = $c->stash('id');
                $c->render( text => qq{Thing $id} );
            }
        ],
        rewrite_url => 1
    );
    $app->ua->server->app($app);

    my $ua   = $app->ua;
    my $host = 'foo.bar.baz.bak';
    $ua->on(
        original_request => sub {
            my ( $ua, $req ) = @_;
            my $url = $req->url;
            is( $url->host, $host, 'Hostname matches' );
        }
    );
    my $tx = $ua->get(qq{http://$host/thing/23});
    is( $tx->res->code, 200, 'Status OK');
    is( $tx->res->body, 'Thing 23', 'Body OK' );
};
done_testing;
