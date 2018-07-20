#! perl -w

use Test::Most;

use Mojolicious::Lite;
use Test::Mojo;

my @tests = ({
        resource      => 'post',
        relationships => ['author', 'comments'],
        namespace     => undef,
        plural        => 'posts',
        resource_path => '/posts',
    },
    {
        resource      => 'person',
        namespace     => 'api',
        plural        => 'people',
        resource_path => '/api/people',
    },
    {
        resource      => 'person',
        namespace     => 'api/v1',
        plural        => 'people',
        resource_path => '/api/v1/people',
    },
    {
        resource      => 'email-template',
        namespace     => 'api/v1',
        plural        => 'email-templates',
        resource_path => '/api/v1/email-templates',
    },
);

foreach my $test (@tests) {
    my $resource      = $test->{resource};
    my $resource_path = $test->{resource_path};
    my $namespace     = $test->{namespace};
    my $plural        = $test->{plural};
    my $param_id      = $resource . '_id';
    $param_id =~ s/-/_/g;

    my $t = Test::Mojo->new();

    $t->app->plugin('JSONAPI', { namespace => $namespace });

    $t->app->hook(
        before_render => sub {
            my ($c)    = @_;
            my $method = $c->tx->req->method;
            my $path   = $c->tx->req->url->path;

            if ($path =~ m{$resource_path}) {    # if the path is for the current resource
                if ($method =~ m/PATCH|DELETE/) {
                    is($c->param($param_id), 20, "$param_id placeholder is there for $method $path");
                }

                if ($method eq 'GET' && $path ne $resource_path) {
                    is($c->param($param_id), 20, "$param_id placeholder is there for $method $path");
                }
            }
        });

    $t->app->hook(
        after_dispatch => sub {
            my ($c) = @_;
            return $c->render(
                status => 200,
                json   => {});
        });

    $t->app->resource_routes({
        resource      => $resource,
        relationships => $test->{relationships},
    });

    $t->get_ok($resource_path)->status_is(200);
    $t->post_ok($resource_path)->status_is(200);

    $t->get_ok("$resource_path/20")->status_is(200);
    $t->patch_ok("$resource_path/20")->status_is(200);
    $t->delete_ok("$resource_path/20")->status_is(200);

    foreach my $relationship (@{ $test->{relationships} // [] }) {
        $t->get_ok("$resource_path/20/relationships/$relationship")->status_is(200);
        $t->post_ok("$resource_path/20/relationships/$relationship")->status_is(200);
        $t->patch_ok("$resource_path/20/relationships/$relationship")->status_is(200);
        $t->delete_ok("$resource_path/20/relationships/$relationship")->status_is(200);
    }
}

done_testing;
