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

done_testing();
