#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Temp ();

# The view registry: engine resolution at to_app, the default engine,
# per-render engine/type/status overrides, +Class escape, and the
# Stencil adapter end-to-end (wrapper, filters, escaping).

my $dir = File::Temp->newdir;
{
    open my $fh, '>', "$dir/layout.tmpl" or die $!;
    print $fh "<html>{% content %}</html>";
    close $fh;
    open $fh, '>', "$dir/hello.tmpl" or die $!;
    print $fh "<p>{% name %} owes {% amount | money %}</p>";
    close $fh;
}

# a second, trivial engine to prove pluggability
{
    package My::Test::View;
    sub new    { bless { %{ $_[1] } }, $_[0] }
    sub render { my ($self, $tpl, $data) = @_;
                 "[$self->{tag}] $tpl name=$data->{name}" }
}

{
    package ViewApp;
    use Punk;
    views Stencil => {
        template_dir => "$dir",
        wrapper      => 'layout.tmpl',
        filters      => { money => sub { sprintf '%.2f', $_[0] } },
    };
    views '+My::Test::View' => { tag => 'alt' };
    get '/page' => sub {
        $_[0]->render('hello', { name => 'R<x>', amount => 3 });
    };
    get '/alt' => sub {
        $_[0]->render('hello', { name => 'n' }, engine => 'My::Test::View',
                      type => 'text/plain');
    };
    get '/status' => sub {
        $_[0]->render('hello', { name => 'n', amount => 1 }, status => 402);
    };
    get '/chained' => sub {
        my ($c) = @_;
        $c->status(203)->header('X-View' => 1);
        return $c->render('hello', { name => 'n', amount => 1 });
    };
    package main;
}

my $app = ViewApp->to_app;

{
    my $r = hit($app, path => '/page');
    is($r->[0], 200, 'render serves');
    my %h = @{ $r->[1] };
    is($h{'Content-Type'}, 'text/html; charset=utf-8', 'html by default');
    is($h{'Content-Length'}, length $r->[2][0], 'content length matches');
    like($r->[2][0], qr{\A<html><p>}, 'wrapper applied (first engine default)');
    like($r->[2][0], qr{R&lt;x&gt;}, 'Stencil auto-escapes');
    like($r->[2][0], qr{3\.00}, 'user filter ran');
}
{
    my $r = hit($app, path => '/alt');
    is($r->[2][0], '[alt] hello name=n', 'per-render engine override');
    my %h = @{ $r->[1] };
    is($h{'Content-Type'}, 'text/plain', 'type override');
}
is(hit($app, path => '/status')->[0], 402, 'status override');
{
    my $r = hit($app, path => '/chained');
    is($r->[0], 203, 'status set through $c folds into render');
    my %h = @{ $r->[1] };
    is($h{'X-View'}, 1, 'header set through $c folds into render');
}

# ---- boot-time croaks --------------------------------------------------------
{
    package NoViews;
    use Punk;
    get '/x' => sub { $_[0]->render('hello') };
    package main;
    my $r = hit(NoViews->to_app, path => '/x');
    is($r->[0], 500, 'render without views is an error');
    like($r->[2][0], qr/no view engine configured/, 'with the hint');
}
{
    package BadEngine;
    use Punk;
    views 'NoSuchEngine' => {};
    package main;
    my $err = '';
    eval { BadEngine->to_app } or $err = $@;
    like($err, qr/NoSuchEngine.*failed to load/s,
        'unknown engine croaks at to_app');
}
{
    package UnknownAtRender;
    use Punk;
    views '+My::Test::View' => { tag => 'only' };
    get '/x' => sub { $_[0]->render('t', {}, engine => 'Missing') };
    package main;
    my $r = hit(UnknownAtRender->to_app, path => '/x');
    is($r->[0], 500, 'unknown engine name at render is an error');
    like($r->[2][0], qr/no view engine 'Missing'/, 'naming the engine');
    like($r->[2][0], qr/My::Test::View/, 'and listing what is registered');
}

done_testing();
