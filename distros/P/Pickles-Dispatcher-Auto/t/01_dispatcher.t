use strict;
use MyApp::Dispatcher;
use MyApp::Context;
use HTTP::Request;
use HTTP::Response;
use HTTP::Message::PSGI;
use Plack::Test;
use Test::More;

my $dispatcher = MyApp::Dispatcher->new( file => 't/MyApp/etc/routes.pl' );
isa_ok($dispatcher, 'MyApp::Dispatcher');

subtest "auto dispatch" => sub {
    {
        my $req = HTTP::Request->new(GET => 'http://localhost/foo');
        my $env = $req->to_psgi;
        my $c = MyApp::Context->new($env);

        ok(my $match = $dispatcher->match($c), "create match");
        is($match->{controller}, 'Root', "match controller");
        is($match->{action}, 'foo', "match action");
    }
    {
        my $req = HTTP::Request->new(GET => 'http://localhost/my/');
        my $env = $req->to_psgi;
        my $c = MyApp::Context->new($env);

        ok(my $match = $dispatcher->match($c), "create match");
        is($match->{controller}, 'My::Root', "match controller");
        is($match->{action}, 'index', "match action");
    }
    {
        my $req = HTTP::Request->new(GET => 'http://localhost/my/foo');
        my $env = $req->to_psgi;
        my $c = MyApp::Context->new($env);

        ok(my $match = $dispatcher->match($c), "create match");
        is($match->{controller}, 'My::Root', "match controller");
        is($match->{action}, 'foo', "match action");
    }
    {
        my $req = HTTP::Request->new(GET => 'http://localhost/my/some/');
        my $env = $req->to_psgi;
        my $c = MyApp::Context->new($env);

        ok(my $match = $dispatcher->match($c), "create match");
        is($match->{controller}, 'My::Some::Root', "match controller");
        is($match->{action}, 'index', "match action");
    }
    {
        my $req = HTTP::Request->new(GET => 'http://localhost/my/some/foo');
        my $env = $req->to_psgi;
        my $c = MyApp::Context->new($env);

        ok(my $match = $dispatcher->match($c), "create match");
        is($match->{controller}, 'My::Some::Root', "match controller");
        is($match->{action}, 'foo', "match action");
    }
    {
        my $req = HTTP::Request->new(GET => 'http://localhost/my/some/klass/');
        my $env = $req->to_psgi;
        my $c = MyApp::Context->new($env);

        ok(my $match = $dispatcher->match($c), "create match");
        is($match->{controller}, 'My::Some::Klass::Root', "match controller");
        is($match->{action}, 'index', "match action");
    }
    {
        my $req = HTTP::Request->new(GET => 'http://localhost/my/some/klass/foo');
        my $env = $req->to_psgi;
        my $c = MyApp::Context->new($env);

        ok(my $match = $dispatcher->match($c), "create match");
        is($match->{controller}, 'My::Some::Klass::Root', "match controller");
        is($match->{action}, 'foo', "match action");
    }
};

subtest "static routing by routes.pl" => sub {
    {
        my $req = HTTP::Request->new(GET => 'http://localhost/item/1');
        my $env = $req->to_psgi;
        my $c = MyApp::Context->new( $env );

        ok(my $match = $dispatcher->match($c), "create match");
        is($match->{controller}, 'Item', "match controller");
        is($match->{action}, 'view', "match action");
        is($match->{args}->{id}, '1', "args check");
    }
    {
        my $req = HTTP::Request->new(GET => 'http://localhost/my/item/2');
        my $env = $req->to_psgi;
        my $c = MyApp::Context->new( $env );

        ok(my $match = $dispatcher->match($c), "create match");
        is($match->{controller}, 'My::Item', "match controller");
        is($match->{action}, 'view', "match action");
        is($match->{args}->{id}, '2', "args check");
    }
    {
        my $req = HTTP::Request->new(GET => 'http://localhost/my/some/item/3');
        my $env = $req->to_psgi;
        my $c = MyApp::Context->new( $env );

        ok(my $match = $dispatcher->match($c), "create match");
        is($match->{controller}, 'My::Some::Item', "match controller");
        is($match->{action}, 'view', "match action");
        is($match->{args}->{id}, '3', "args check");
    }
    {
        my $req = HTTP::Request->new(GET => 'http://localhost/my/some/klass/item/4');
        my $env = $req->to_psgi;
        my $c = MyApp::Context->new( $env );

        ok(my $match = $dispatcher->match($c), "create match");
        is($match->{controller}, 'My::Some::Klass::Item', "match controller");
        is($match->{action}, 'view', "match action");
        is($match->{args}->{id}, '4', "args check");
    }
};

done_testing;
