#! perl -w

use Test::Most;
use Mojolicious::Lite;
use Test::Mojo;

use_ok('Mojolicious::Plugin::JSONAPI');

plugin 'JSONAPI', { data_dir => 't/share' };

my $test = [];    # modified in each subtest for different scenarios

get '/' => sub {
    my ($c) = @_;
    my $includes = $c->requested_resources();
    is_deeply($includes, $test, 'parsed include param into array');
    $c->render(status => 200, json => {});
};

my $t = Test::Mojo->new();

subtest 'empty include' => sub {
    $t->get_ok('/');
};

subtest 'one included resource' => sub {
    $test = ['comments'];
    $t->get_ok('/?include=comments');
};

subtest 'multiple included resources' => sub {
    $test = [qw/comments author posts/];
    $t->get_ok('/?include=comments,author,posts');
};

subtest 'with dashes' => sub {
    $test = [qw/author email_templates/];
    $t->get_ok('/?include=author,email-templates');
};

subtest 'nested relationships' => sub {
    $test = [{ author => [qw/posts/] }, 'email_templates'];
    $t->get_ok('/?include=author.posts,email-templates');
};

done_testing;
