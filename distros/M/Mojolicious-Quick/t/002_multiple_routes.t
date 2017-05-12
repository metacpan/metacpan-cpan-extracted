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
    my $t = Test::Mojo->new($app);
    for my $verb (qw/get post put patch/) {
        my $method = sprintf '%s_ok', $verb;
        $t->$method('/thing/23')->status_is(200)->content_is('Thing 23');
        $t->$method('/other/thing/23')->status_is(200)->content_is('Other thing 23');
        $t->$method('/another/thing/23')->status_is(200)->content_is('Another thing 23');
    }
};

subtest 'route by HTTP verb with arrayrefs' => sub {
    my $args = [];
    for my $verb (qw/GET POST PUT PATCH DELETE OPTIONS/) {
        push @{$args}, $verb;
        push @{$args}, [
            '/thing/:id' => sub {
                my $c       = shift;
                my $id      = $c->stash('id');
                my $whatsis = $c->param('whatsis');
                $c->render( json => { 'id' => $id, whatsis => $whatsis, otherness => 'none', 'method' => lc $verb } );
            },
            '/other/thing/:id' => sub {
                my $c       = shift;
                my $id      = $c->stash('id');
                my $whatsis = $c->param('whatsis');
                $c->render(
                    json => { 'id' => $id, whatsis => $whatsis, 'otherness' => 'other', 'method' => lc $verb } );
            },
            '/another/thing/:id' => sub {
                my $c       = shift;
                my $id      = $c->stash('id');
                my $whatsis = $c->param('whatsis');
                $c->render(
                    json => { 'id' => $id, whatsis => $whatsis, 'otherness' => 'another', 'method' => lc $verb } );
            },
        ];
    }
    my $app = Mojolicious::Quick->new($args);
    my $t = Test::Mojo->new($app);
    for my $verb (qw/get post put patch options delete/) {
        my $method = sprintf '%s_ok', $verb;
        my $whatsis = random_string('ccc');
        my $id = random_string('nnnnn');
        my $expected = {
            id => $id,
            whatsis => $whatsis,
            method => $verb,
        };
        for my $path ('/thing', '/other/thing', '/another/thing') {
            my $expected = {%{$expected}};
            my $otherness = $path eq '/thing' ? 'none' : $path =~ /^\/other/ ? 'other' : 'another';
            $expected->{'otherness'} = $otherness;
            $t->$method(qq{$path/$id} => form => { whatsis => $whatsis })->status_is(200)->json_is($expected);
        }
    }
};

done_testing;

