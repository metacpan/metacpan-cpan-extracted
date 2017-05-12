use strict;
use warnings;
use Test::More;
use Nephia::Core;
use Plack::Test;
use HTTP::Request::Common;

{
    package Nephia::Plugin::HookTester;
    use parent 'Nephia::Plugin';
    use Plack::Request;

    sub new {
        my ($class, %opts) = @_;
        my $self = $class->SUPER::new(%opts);
        $self->app->action_chain->prepend('HookTest::ActionPrepend' => $self->can('before_action'));
        $self->app->action_chain->append('HookTest::ActionAppend' => $self->can('after_action'));
        $self->app->filter_chain->append('HookTest::FilterAppend' => $self->can('modify_body'));
        return $self;
    }

    sub before_action {
        my ($app, $context) = @_; 
        $context->set(clever => 'ytnobody');
        return $context;
    }

    sub after_action {
        my ($app, $context) = @_;
        my $clever = $context->get('clever');
        my $name   = $context->{req}->param('name');
        return $context unless $name;
        return
            $context->{req}->param('name') eq $clever ? 
            ($context, [200, [], ["You clever!"]]) :
            $context
        ;
    }

    sub modify_body {
        my ($app, $body) = @_;
        $body =~ s/Hello/Ciao/g;
        return $body;
    }
};

my $v = Nephia::Core->new(
    appname => 'MyApp',
    plugins => ['HookTester'],
    app => sub {
        my $name = param('name') || 'tonkichi';
        [200, [], ["Hello, $name"]];
    },
);

my $app = $v->run;

subtest default => sub {
    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->content, 'Ciao, tonkichi', 'Ciao, tonkichi';
        $res = $cb->(GET '/?name=ytnobody');
        is $res->content, 'You clever!', 'ytnobody, clever!';
    };
};

done_testing;
