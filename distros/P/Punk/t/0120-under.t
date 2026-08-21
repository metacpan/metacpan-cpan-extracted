#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;

# under scopes: guard order, short-circuit, nesting, prefixes, and the
# before_dispatch hook running ahead of guards.

my @order;

{
    package UnderApp;
    use Punk;

    hook before_dispatch => sub { push @order, 'hook'; return };

    my $outer = under '/a' => sub {
        my ($c) = @_;
        push @order, 'outer';
        return $c->text('stopped by outer', 403)
            if ($c->req->param('stop') // '') eq 'outer';
        return;
    };
    $outer->get('/leaf' => sub { push @order, 'handler'; $_[0]->text('leaf') });

    my $inner = $outer->under('/b' => sub {
        my ($c) = @_;
        push @order, 'inner';
        return [ 401, ['Content-Type' => 'text/plain', 'Content-Length' => 2],
                 ['no'] ] if $c->req->param('stop');
        return;
    });
    $inner->get('/deep' => sub { push @order, 'deep'; $_[0]->text('deep') });

    package main;
}

my $app = UnderApp->to_app;

{
    @order = ();
    my $r = hit($app, path => '/a/leaf');
    is($r->[2][0], 'leaf', 'guarded route serves');
    is_deeply(\@order, [qw(hook outer handler)],
        'hook, then guard, then handler');
}
{
    @order = ();
    my $r = hit($app, path => '/a/b/deep');
    is($r->[2][0], 'deep', 'nested scope serves under both prefixes');
    is_deeply(\@order, [qw(hook outer inner deep)],
        'guards run outer to inner');
}
{
    @order = ();
    my $r = hit($app, path => '/a/b/deep', query => 'stop=1');
    is($r->[0], 401, 'inner guard short-circuits with its triplet');
    is_deeply(\@order, [qw(hook outer inner)], 'handler never ran');
}
is(hit($app, path => '/leaf')->[0], 404, 'the unprefixed path is not routed');

# ---- prefixes compose; root-path route under a scope -------------------------
{
    package RootScope;
    use Punk;
    my $s = under '/api' => sub { return };
    $s->get('/' => sub { $_[0]->text('api root') });
    package main;
    is(hit(RootScope->to_app, path => '/api')->[2][0], 'api root',
        "scope + '/' routes the bare prefix");
}

# ---- guard targets resolve like route targets --------------------------------
{
    package GuardTarget;
    use Punk;
    my $s = under '/g' => 'Web::Gate#check';
    $s->get('/in' => sub { $_[0]->text('in') });
    package GuardTarget::Controller::Web::Gate;
    sub check {
        my ($c) = @_;
        return $c->text('blocked', 403) unless $c->req->header('x-ok');
        return;
    }
    package main;
    my $app2 = GuardTarget->to_app;
    is(hit($app2, path => '/g/in')->[0], 403, 'string guard blocks');
    is(hit($app2, path => '/g/in', env => { HTTP_X_OK => 1 })->[2][0], 'in',
        'string guard passes');
}

done_testing();
