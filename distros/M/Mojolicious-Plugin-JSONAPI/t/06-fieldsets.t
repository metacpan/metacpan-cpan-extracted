#! perl -w

use Test::Most;
use Mojolicious::Lite;
use Test::Mojo;

use_ok('Mojolicious::Plugin::JSONAPI');

{
    plugin 'JSONAPI', { namespace => 'api', data_dir => 't/share' };

    my $test = {};    # modified in each subtest for different scenarios

    get '/api/resource' => sub {
        my ($c) = @_;
        my $fields = $c->requested_fields();
        is_deeply($fields, $test, 'included fields for the resource');
        $c->render(status => 200, json => {});
    };

    get '/api/resource/relationships/author' => sub {
        my ($c) = @_;
        my $fields = $c->requested_fields();
        is_deeply($fields, $test, 'included fields for the resource for relationship route');
        $c->render(status => 200, json => {});
    };

    my $t = Test::Mojo->new();

    subtest 'no fields specified' => sub {
        $t->get_ok('/api/resource');
    };

    subtest 'main resource fields' => sub {
        $test = { fields => [qw/comments blogs/], };
        $t->get_ok('/api/resource?fields[resource]=comments,blogs');
    };

    subtest 'main resources field and relation fields' => sub {
        $test = {
            fields         => [qw/comments blogs/],
            related_fields => {
                author => [qw/name number/] } };
        $t->get_ok('/api/resource?fields[resource]=comments,blogs&fields[author]=name,number');
    };

    subtest 'can get main resource from related route' => sub {
        $test = {
            fields         => [qw/comments blogs/],
            related_fields => {
                author => [qw/name number/] } };
        $t->get_ok('/api/resource/relationships/author?fields[resource]=comments,blogs&fields[author]=name,number');
    };
}

{    # Without namespace
    plugin 'JSONAPI', { data_dir => 't/share' };

    my $test = {};    # modified in each subtest for different scenarios

    get '/weezle' => sub {
        my ($c) = @_;
        my $fields = $c->requested_fields();
        is_deeply($fields, $test, 'included fields for the resource');
        $c->render(status => 200, json => {});
    };

    get '/weezle/relationships/author' => sub {
        my ($c) = @_;
        my $fields = $c->requested_fields();
        is_deeply($fields, $test, 'included fields for the resource for relationship route');
        $c->render(status => 200, json => {});
    };

    my $t = Test::Mojo->new();

    subtest 'no fields specified' => sub {
        $t->get_ok('/api/weezle');
    };

    subtest 'main resource fields' => sub {
        $test = { fields => [qw/comments blogs/], };
        $t->get_ok('/weezle?fields[weezle]=comments,blogs');
    };

    subtest 'main resources field and relation fields' => sub {
        $test = {
            fields         => [qw/comments blogs/],
            related_fields => {
                author => [qw/name number/] } };
        $t->get_ok('/weezle?fields[weezle]=comments,blogs&fields[author]=name,number');
    };

    subtest 'can get main resource from related route' => sub {
        $test = {
            fields         => [qw/comments blogs/],
            related_fields => {
                author => [qw/name number/] } };
        $t->get_ok('/weezle/relationships/author?fields[weezle]=comments,blogs&fields[author]=name,number');
    };
}

done_testing;
