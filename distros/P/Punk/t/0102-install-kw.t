#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use B ();

# $app->install_kw($name => $code): the supported way for a plugin to add a
# declaration keyword to an application class, so no plugin has to assign to
# a glob. What is tested here is the mechanism - the call shape, the
# collision rules and the reach of the install.

our @SEEN;

# ---- a keyword is a keyword ---------------------------------------------------

{
    {
        package KwApp;
        use Punk;
        # a plugin installs from its import, i.e. at compile time, which is
        # what makes the bareword form on the lines below parse
        BEGIN {
            KwApp->punk_app->install_kw(record => sub {
                push @main::SEEN, [@_];
                return wantarray ? (1, 2, 3) : 'scalar';
            }, 'Some::Plugin');
        }

        record 'a', 'b';                       # bareword, no parens
        record('c');
    }

    is_deeply(\@SEEN, [['a', 'b'], ['c']],
        'the keyword parses as a list operator and gets its arguments');

    ok(KwApp->can('record'), 'it is a real sub in the application class');
    ok(B::svref_2object(KwApp->can('record'))->XSUB,
        '...an XSUB, like the DSL keywords it sits beside');
    is(B::svref_2object(KwApp->can('record'))->GV->NAME, 'record',
        '...named for the keyword');
    is(B::svref_2object(KwApp->can('record'))->GV->STASH->NAME, 'KwApp',
        '...in the class it was installed into');
}

# ---- context is propagated, not forced ----------------------------------------

{
    my $scalar = KwApp::record();
    my @list   = KwApp::record();
    is($scalar, 'scalar', 'a scalar-context call gets the scalar return');
    is_deeply(\@list, [1, 2, 3], 'and a list-context call keeps its list');
}

# ---- the install reaches one class only ---------------------------------------

{
    {
        package OtherApp;
        use Punk;
    }
    ok(!OtherApp->can('record'),
        'a keyword installed in one application does not leak into another');
    ok(!main->can('record'), '...nor into the caller of install_kw');
}

# ---- chaining -----------------------------------------------------------------

{
    {
        package ChainApp;
        use Punk;
    }
    my $app = ChainApp->punk_app;
    is($app->install_kw(one => sub { 1 }, 'P')->install_kw(two => sub { 2 }, 'P'),
       $app, 'install_kw chains by returning the registrar');
    ok(ChainApp->can($_), "$_ installed") for qw(one two);
}

# ---- the same owner may install twice -----------------------------------------
# A plugin with two entry points (an import that installs the keywords and a
# register that installs them again, in case the app said `plugin` first)
# must not have to remember which one ran.

{
    {
        package TwiceApp;
        use Punk;
    }
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    my $app = TwiceApp->punk_app;
    $app->install_kw(again => sub { 'first' }, 'Some::Plugin');
    my $ok = eval {
        $app->install_kw(again => sub { 'second' }, 'Some::Plugin'); 1 };
    ok($ok, 'the same owner installing the same keyword twice is a no-op')
        or diag $@;
    is(TwiceApp::again(), 'first', '...and the first install is the one kept');
    is_deeply([grep { /redefin/i } @warn], [],
        '...with no redefinition warning');
}

# ---- collisions ---------------------------------------------------------------

{
    {
        package ClashApp;
        use Punk;
    }
    my $app = ClashApp->punk_app;
    $app->install_kw(mine => sub { 1 }, 'Plugin::A');
    my $err = '';
    eval { $app->install_kw(mine => sub { 2 }, 'Plugin::B'); 1 } or $err = $@;
    like($err, qr/keyword 'mine' is installed by both Plugin::A and Plugin::B/,
        'two owners claiming one keyword croaks, naming both');
}

{
    {
        package DslApp;
        use Punk;
    }
    my $before = DslApp->can('get');
    my $err = '';
    eval { DslApp->punk_app->install_kw(get => sub { 1 }, 'P'); 1 } or $err = $@;
    like($err, qr/keyword 'get' is part of the Punk DSL/,
        'a core DSL keyword cannot be installed over');
    is(DslApp->can('get'), $before, '...and the real one is untouched');
}

{
    {
        package BadApp;
        use Punk;
    }
    my $app = BadApp->punk_app;
    my $err = '';
    eval { $app->install_kw(nope => 'not a coderef', 'P'); 1 } or $err = $@;
    like($err, qr/needs a name and a code reference/,
        'a keyword needs a coderef');
    $err = '';
    eval { $app->install_kw('' => sub { 1 }, 'P'); 1 } or $err = $@;
    like($err, qr/needs a name and a code reference/, '...and a name');
    ok(!BadApp->can('nope'), 'nothing was installed by the failed calls');
}

# ---- the owner defaults to the caller -----------------------------------------

{
    {
        package OwnerApp;
        use Punk;
    }
    my $err = '';
    OwnerApp->punk_app->install_kw(defaulted => sub { 1 });   # owner: main
    eval { OwnerApp->punk_app->install_kw(defaulted => sub { 2 }, 'Elsewhere'); 1 }
        or $err = $@;
    like($err, qr/installed by both main and Elsewhere/,
        'an omitted owner is the calling package');
}

done_testing();
