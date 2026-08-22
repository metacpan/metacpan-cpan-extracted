#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;

# The DSL records; to_app resolves and croaks on anything wrong; plugins
# get the registrar and helpers install on the per-app context subclass.

{
    package DslApp;
    use Punk;
    get '/ping' => sub { my ($c) = @_; $c->text('pong') };
    helper shout => sub { my ($c, $word) = @_; uc $word };
    package main;
}

{
    my $app = DslApp->to_app;
    is(ref $app, 'CODE', 'to_app returns a coderef');
    is(hit($app, path => '/ping')->[2][0], 'pong', 'a route serves');
    isa_ok(DslApp::punk_app(), 'Punk::App', 'punk_app');
}

# ---- target resolution croaks at boot ---------------------------------------
{
    package BadTarget;
    use Punk;
    get '/x' => 'Web::Nope#missing';
    package main;
    my $err = '';
    eval { BadTarget->to_app } or $err = $@;
    like($err, qr/Web::Nope#missing/, 'unknown controller croaks at to_app');
}

{
    package BadMethod;
    use Punk;
    get '/x' => 'Web::Real#nope';
    package BadMethod::Controller::Web::Real;
    sub exists_ok { }
    package main;
    my $err = '';
    eval { BadMethod->to_app } or $err = $@;
    like($err, qr/no method 'nope'/, 'missing method croaks at to_app');
}

# ---- plugins ----------------------------------------------------------------
{
    package Punk::Plugin::TestCounter;
    our @ISA = ('Punk::Plugin');
    sub register {
        my ($self, $app, $opts) = @_;
        $app->helper(counted => sub { my ($c) = @_; $c->stash->{n} });
        $app->hook(before_dispatch => sub {
            my ($c) = @_;
            $c->stash->{n} = ($opts->{start} // 0) + 1;
            return;
        });
        $app->route(GET => '/plugged', sub {
            my ($c) = @_;
            $c->text('n=' . $c->counted);
        });
    }
    package PluginApp;
    use Punk;
    plugin 'TestCounter' => { start => 41 };
    get '/shout' => sub { my ($c) = @_; $c->text($c->yell('hi')) };
    helper yell => sub { my ($c, $w) = @_; uc($w) . '!' };
    package main;

    my $app = PluginApp->to_app;
    is(hit($app, path => '/plugged')->[2][0], 'n=42',
        'plugin route + hook + helper cooperate');
    is(hit($app, path => '/shout')->[2][0], 'HI!',
        'app-level helper installs too');
}

# ---- helper collisions croak ------------------------------------------------
{
    package CollideCore;
    use Punk;
    package main;
    my $err = '';
    eval { CollideCore::punk_app()->helper(render => sub { }) } or $err = $@;
    like($err, qr/collides with a Punk::Context method/,
        'core method collision croaks');
}
{
    package CollideTwice;
    use Punk;
    helper thing => sub { 1 };
    package main;
    my $err = '';
    eval { CollideTwice::punk_app()->helper(thing => sub { 2 }, 'Elsewhere') }
        or $err = $@;
    like($err, qr/registered by both/, 'double helper registration croaks');
    like($err, qr/Elsewhere/, 'the error names the second owner');
}

# ---- unknown hook name croaks ------------------------------------------------
{
    package BadHook;
    use Punk;
    package main;
    my $err = '';
    eval { BadHook::punk_app()->hook(nope => sub { }) } or $err = $@;
    like($err, qr/unknown hook 'nope'/, 'unknown hook croaks');
}

# ---- keywords that refuse the wrong shape ------------------------------------
#
# Each of these reads its arguments off the stack by position, so a caller who
# passes the wrong shape does not get a wrong value - they get whatever was in
# the next slot. The croaks are the difference, and none of them had ever been
# reached: every existing test calls these keywords correctly, which is exactly
# why the refusals needed their own.
{
    my $try = sub {
        my ($pkg, $code) = @_;
        my $err = '';
        eval "package $pkg; use Punk; $code; 1" or $err = $@;
        return $err;
    };

    like($try->('UD2', "upload_dir('')"), qr/upload_dir needs a directory/,
        'upload_dir refuses an empty path - which is what an unset config '
      . 'value gives you, and it decides which filesystem attacker-controlled '
      . 'bytes land on');

    like($try->('UA1', "ua('name', 'timeout', 5)"),
        qr/ua takes a hashref, a list of pairs/,
        'ua with an argument list that is not pairs is refused rather than '
      . 'dropping the odd one out');

    # headers_scoped is the registrar method behind $scope->headers. The scope
    # builds the hashref itself, so this guard only answers a direct call -
    # which is what a plugin adding scoped headers would make.
    {
        package HS1;
        use Punk;
        package main;
        my $err = '';
        eval { HS1::punk_app()->headers_scoped('/api', 'X-Thing') } or $err = $@;
        like($err, qr/headers_scoped takes a prefix and a hashref/,
            'headers_scoped refuses anything but a hashref, so a plugin '
          . 'calling it with pairs is told rather than storing a string as '
          . 'a whole header policy');
    }
}

# ---- $c->secret without the config keyword -----------------------------------
# The secrets system fails closed everywhere else, and this is the same rule at
# the other end: asking for a secret when nothing was loaded is an error, not
# an undef that ends up signing something.
{
    package NoConfigApp;
    use Punk;
    get '/s' => sub { $_[0]->text($_[0]->app->secret('session_key') // 'undef') };
    package main;

    my $r = hit(NoConfigApp->to_app, path => '/s');
    is($r->[0], 500,
        'asking for a secret with no config loaded is refused, rather than '
      . 'handing back undef for something about to be used as a key');
    like($r->[2][0], qr/no configuration loaded/,
        'and the message names the keyword that is missing');
}

done_testing();
