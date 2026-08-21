#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use B ();

# `use Punk` itself (punk_import.h): the pragmas it turns on, the registrar it
# caches, and the DSL it installs. The keywords are exercised all over the
# suite; what is tested here is the export mechanism behind them, which
# nothing else touches.

# ---- it is the XSUB, and so is everything it installs -------------------------

{
    ok(B::svref_2object(Punk->can('import'))->XSUB, 'Punk::import is an XSUB');

    {
        package Exported;
        use Punk;
    }
    my @kw = qw(get post put patch del any under api websocket sse session
                csrf cors logging docs static mount views config secret
                database model hook middleware on_error plugin helper
                to_app punk_app);
    my @missing = grep { !Exported->can($_) } @kw;
    is_deeply(\@missing, [], 'every documented keyword is installed');

    my @perl = grep { !B::svref_2object(Exported->can($_))->XSUB } @kw;
    is_deeply(\@perl, [], '...and all of them are XSUBs');
}

# ---- the pragmas ---------------------------------------------------------------

{
    my $err = '';
    eval q{ package StrictOn; use Punk; $undeclared_variable = 1; 1 } or $err = $@;
    like($err, qr/explicit package name|requires explicit/,
        'use Punk turns strict on in the caller');
}

{
    my $warned;
    local $SIG{__WARN__} = sub { $warned = shift };
    eval q{
        package WarnOn;
        use Punk;
        my $undef;
        my $sum = $undef + 1;
        1;
    };
    like($warned, qr/uninitialized/, 'and warnings');
}

{   # the DSL is installed into the caller, not exported at large: a package
    # that never said `use Punk` must not have acquired routing keywords
    {
        package Untouched;
        sub nothing { 1 }
    }
    my @leaked = grep { Untouched->can($_) } qw(get post under to_app punk_app);
    is_deeply(\@leaked, [],
        'a package that never said `use Punk` gets no keywords');
}

# ---- one registrar per class ---------------------------------------------------

{
    {
        package Twice;
        use Punk;
        get '/first' => sub { $_[0]->text('first') };
        use Punk;                      # a second use, e.g. after a package split
        get '/second' => sub { $_[0]->text('second') };
    }
    my $app = Twice->to_app;
    for my $p ('/first', '/second') {
        my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => $p,
                         QUERY_STRING => '', SERVER_NAME => 'l',
                         SERVER_PORT => 80, HTTP_HOST => 'l',
                         'psgi.url_scheme' => 'http' });
        is($r->[0], 200, "a second `use Punk` keeps $p");
    }
    is(scalar @{[ grep { $_ eq 'Twice' } keys %Punk::APPS ]}, 1,
        'and there is still one registrar for the class');
}

{
    {
        package AppOne; use Punk; get '/only-one' => sub { $_[0]->text('1') };
        package AppTwo; use Punk; get '/only-two' => sub { $_[0]->text('2') };
    }
    isnt(AppOne->punk_app, AppTwo->punk_app,
        'two classes get two registrars');

    my $one = AppOne->to_app;
    my $call = sub {
        my ($app, $p) = @_;
        return $app->({ REQUEST_METHOD => 'GET', PATH_INFO => $p,
                        QUERY_STRING => '', SERVER_NAME => 'l',
                        SERVER_PORT => 80, HTTP_HOST => 'l',
                        'psgi.url_scheme' => 'http' })->[0];
    };
    is($call->($one, '/only-one'), 200, 'one class has its own routes');
    is($call->($one, '/only-two'), 404, "...and not the other's");
}

# ---- the five keyword shapes ---------------------------------------------------
# Each row in the table takes one of five forms; a mistake in the shape would
# show up as an argument in the wrong place, which is exactly what these check.

{
    {
        package Shapes;
        use Punk;
        get  '/g' => sub { $_[0]->text('g') };
        post '/p' => sub { $_[0]->text('p') };
        del  '/d' => sub { $_[0]->text('d') };
        any  '/a' => sub { $_[0]->text('a') };
        helper shout => sub { uc $_[1] };
        get  '/shout' => sub { $_[0]->text($_[0]->shout('hi')) };
    }
    my $app = Shapes->to_app;
    my $call = sub {
        my ($m, $p) = @_;
        return $app->({ REQUEST_METHOD => $m, PATH_INFO => $p,
                        QUERY_STRING => '', SERVER_NAME => 'l',
                        SERVER_PORT => 80, HTTP_HOST => 'l',
                        'psgi.url_scheme' => 'http' });
    };

    # PKW_ROUTE: the verb is captured, the path and target are the arguments
    is($call->('GET',  '/g')->[2][0], 'g', 'get routes GET');
    is($call->('POST', '/p')->[2][0], 'p', 'post routes POST');
    is($call->('DELETE', '/d')->[2][0], 'd', 'del routes DELETE');
    is($call->('PUT',  '/a')->[2][0], 'a', 'any routes every method');
    is($call->('POST', '/g')->[0], 405, 'and a verb does not answer another');

    # PKW_HELPER: the owning class is appended, not passed by the caller
    is($call->('GET', '/shout')->[2][0], 'HI', 'helper installs a method');

    # PKW_SELF - to_app (PKW_NOARG) gets its own class below, because a
    # registrar compiles once and $app above already used this one
    isa_ok(Shapes->punk_app, 'Punk::App', 'punk_app returns the registrar');
    is(ref $app, 'CODE', 'to_app returned a PSGI coderef');
}

{   # PKW_NOARG really ignores its arguments: to_app is called as a class
    # method, so the class name must not reach Punk::App::compile as an
    # argument. (One compile per registrar - a second to_app on the same class
    # croaks - so this needs its own.)
    {
        package Noarg;
        use Punk;
        get '/n' => sub { $_[0]->text('n') };
    }
    my $app = Noarg::to_app('Noarg', 'extra', 'junk');
    is(ref $app, 'CODE', 'to_app ignores whatever it is handed');
    is($app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/n', QUERY_STRING => '',
                SERVER_NAME => 'l', SERVER_PORT => 80, HTTP_HOST => 'l',
                'psgi.url_scheme' => 'http' })->[2][0], 'n',
        'and the app it returns works');
}

# ---- the keywords return what the registrar returns ----------------------------

{
    {
        package Returns;
        use Punk;
    }
    my $scope = Returns::under('/admin', sub { return });
    isa_ok($scope, 'Punk::Router::Scope', 'under returns the scope object');

    # chaining keywords hand back the registrar
    my $chained = Returns::views('Stencil', { template_dir => '/tmp' });
    isa_ok($chained, 'Punk::App', 'views chains by returning the registrar');
}

{   # context is propagated rather than forced: a list-context call must not
    # collapse to one value
    {
        package Ctx;
        use Punk;
        helper pair => sub { return (1, 2) };
        get '/pair' => sub {
            my ($c) = @_;
            my @got = $c->pair;
            return $c->text(scalar @got);
        };
    }
    my $r = Ctx->to_app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/pair',
                            QUERY_STRING => '', SERVER_NAME => 'l',
                            SERVER_PORT => 80, HTTP_HOST => 'l',
                            'psgi.url_scheme' => 'http' });
    is($r->[2][0], 2, 'a list-returning helper keeps its list');
}

# ---- errors still come from the registrar --------------------------------------

{
    my $err = '';
    eval {
        package BadHelper;
        use Punk;
        helper render => sub { 1 };      # collides with a core context method
        BadHelper->to_app;
    } or $err = $@;
    like($err, qr/collides with a Punk::Context method/,
        'a helper collision still croaks, naming the clash');
}

{
    my $err = '';
    eval {
        package BadMount;
        use Punk;
        mount '/x' => 'not a coderef';
    } or $err = $@;
    like($err, qr/needs a PSGI coderef/,
        'a keyword\'s own validation is unchanged by the port');
}

done_testing();
