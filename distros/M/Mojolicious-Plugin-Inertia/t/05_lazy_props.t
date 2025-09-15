use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use lib 'lib';

plugin 'Inertia' => {
    version => '1.0.0',
    layout  => '<div id="app" data-page="<%= $data_page %>"></div>'
};

my $expensive_call_count = 0;

get '/lazy' => sub {
    my $c = shift;

    # Regular prop
    my $simple = 'simple value';

    # Lazy prop using code reference
    my $expensive = sub {
        $expensive_call_count++;
        return { computed => 'expensive data', count => $expensive_call_count };
    };

    # Another lazy prop
    my $users = sub {
        return [
            { id => 1, name => 'Alice' },
            { id => 2, name => 'Bob' }
        ];
    };

    $c->inertia('LazyPage', {
        simple => $simple,
        expensive => $expensive,
        users => $users
    });
};

my $t = Test::Mojo->new;

# Reset counter
$expensive_call_count = 0;

# Test that all lazy props are evaluated on full request
$t->get_ok('/lazy' => {'X-Inertia' => 'true'})
  ->status_is(200)
  ->json_is('/props/simple' => 'simple value')
  ->json_is('/props/expensive/computed' => 'expensive data')
  ->json_is('/props/expensive/count' => 1)
  ->json_is('/props/users/0/name' => 'Alice');

is($expensive_call_count, 1, 'Expensive computation called once');

# Test partial reload - expensive prop should be called again
$t->get_ok('/lazy' => {
    'X-Inertia' => 'true',
    'X-Inertia-Partial-Data' => 'expensive',
    'X-Inertia-Partial-Component' => 'LazyPage'
  })
  ->status_is(200)
  ->json_is('/props/expensive/count' => 2)
  ->json_hasnt('/props/simple')
  ->json_hasnt('/props/users');

is($expensive_call_count, 2, 'Expensive computation called on partial reload');

# Test partial reload without expensive prop - should not call it
$t->get_ok('/lazy' => {
    'X-Inertia' => 'true',
    'X-Inertia-Partial-Data' => 'simple',
    'X-Inertia-Partial-Component' => 'LazyPage'
  })
  ->status_is(200)
  ->json_is('/props/simple' => 'simple value')
  ->json_hasnt('/props/expensive')
  ->json_hasnt('/props/users');

is($expensive_call_count, 2, 'Expensive computation not called when not requested');

done_testing();