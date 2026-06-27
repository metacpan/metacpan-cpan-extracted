use strict;
use warnings;

use Test2::V0;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/lib";

use PAGI::Utils qw(to_app);
use TestApps::Component;
use TestApps::FakeMiddleware;

# Helper to capture response events
sub mock_send {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    return ($send, \@sent);
}

subtest 'coderef passes through unchanged' => sub {
    my $app = async sub { my ($scope, $receive, $send) = @_; };
    ref_is to_app($app), $app, 'same reference back';
};

subtest 'component object is compiled via its to_app method' => sub {
    my $component = TestApps::Component->new(body => 'hello');
    my $app = to_app($component);
    is ref($app), 'CODE', 'returns a coderef';

    my ($send, $sent) = mock_send();
    $app->({ type => 'http', method => 'GET', path => '/' }, sub { Future->done }, $send)->get;
    is $sent->[1]{body}, 'hello', 'compiled app serves the component config';
};

subtest 'loaded class name is compiled via class-method to_app' => sub {
    my $app = to_app('TestApps::Component');
    is ref($app), 'CODE', 'returns a coderef';
};

subtest 'unloaded class name is auto-required' => sub {
    ok !TestApps::AutoLoaded->can('to_app'), 'fixture not yet loaded';
    my $app = to_app('TestApps::AutoLoaded');
    is ref($app), 'CODE', 'returns a coderef';

    my ($send, $sent) = mock_send();
    $app->({ type => 'http', method => 'GET', path => '/' }, sub { Future->done }, $send)->get;
    is $sent->[1]{body}, 'autoloaded', 'auto-required component works';
};

subtest 'middleware object gets a guidance croak' => sub {
    my $mw = TestApps::FakeMiddleware->new;
    like dies { to_app($mw) },
        qr/looks like middleware, not an app.*enable/s,
        'croak points at enable()';
};

subtest 'object without to_app croaks' => sub {
    my $obj = bless {}, 'TestApps::NoSuchMethod';
    like dies { to_app($obj) },
        qr/Cannot coerce TestApps::NoSuchMethod object to a PAGI app/,
        'names the class and the problem';
};

subtest 'unloadable class croaks' => sub {
    like dies { to_app('TestApps::DoesNotExist') },
        qr/Failed to load 'TestApps::DoesNotExist'/,
        'load failure surfaces';
};

subtest 'garbage inputs croak' => sub {
    like dies { to_app(undef) }, qr/requires an app/, 'undef croaks';
    like dies { to_app({})    }, qr/Cannot coerce HASH reference/, 'hashref croaks';
    like dies { to_app('not a package name!') },
        qr/Cannot coerce 'not a package name!'/,
        'non-package string croaks without being evaled';
};

done_testing;
