package MyTestModule;
use strict;
use utf8;
use warnings;

sub new { bless $_[1] // +{}, $_[0] }

sub TO_JSON {
    my $self = shift;
    +{ str => $self->{str}, };
}

package main;
use strict;
use utf8;
use warnings;
use JSON::XS qw(decode_json);
use Mojolicious::Lite;
use MojoX::Renderer::JSON::XS;
use Test::Mojo;
use Test::More;
use Test::Pretty;

my $app = app;
$app->renderer->add_handler(json => MojoX::Renderer::JSON::XS->build,);

get '/blessed' => sub {
    my $c = shift;
    my $blessed = MyTestModule->new({ str => 'あいうえ' });
    $c->render(json => { blessed => $blessed });
};

get '/mojo_exception' => sub {
    my $c = shift;
    my $e = Mojo::Exception->new('hoge fuga');
    $c->render(json => { exception => $e });
};

subtest 'Test JSON output' => sub {
    my $t = Test::Mojo->new($app);

    $t->get_ok('/blessed')->status_is(200)->json_is({ blessed => { str => 'あいうえ', }, });
};

subtest 'Test Mojo::Exception output' => sub {
    my $t = Test::Mojo->new($app);

    $t->get_ok('/mojo_exception')->status_is(200)->json_is({ exception => 'hoge fuga', });
};

done_testing;
