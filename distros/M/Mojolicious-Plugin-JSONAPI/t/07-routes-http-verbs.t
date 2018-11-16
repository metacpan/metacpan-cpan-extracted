#! perl -w

use Test::Most;

use Mojolicious::Lite;
use Test::Mojo;

subtest 'specifying specific http verbs' => sub {
    my $t = Test::Mojo->new();

    $t->app->plugin('JSONAPI', { namespace => 'api' });

    $t->app->hook(
        after_dispatch => sub {
            my $c = shift;
            return $c->render(text => 'ok');
        });

    $t->app->resource_routes({
        resource   => 'baby',
        http_verbs => ['get', 'post', 'delete'],
    });

    my @paths   = map { $_->to_string } @{ $t->app->routes->children->[0]->children };
    my @methods = map { @{ $_->via } } @{ $t->app->routes->children->[0]->children };
    cmp_deeply(
        \@paths,
        bag(
            '/api/babies',             # GET
            '/api/babies',             # POST
            '/api/babies/:baby_id',    # GET
            '/api/babies/:baby_id',    # DELETE
        ),
    ) or explain(\@paths);
    cmp_deeply(\@methods, bag('GET', 'GET', 'POST', 'DELETE')) or explain(\@methods);
};

done_testing;
