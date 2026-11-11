#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Temp ();
use File::Path ();
use Test::More;
use PunkTest qw(hit);

# What compile refuses, by message: a route target that is undef, a bare
# word, a method with a space in it or none, a controller with no file, one
# that dies while loading, one that defined some subs before dying and one
# that loads but has no such method, named short, in full and from outside
# the application's namespace; a model that is not a Punk::Model, one that
# declares no table and one whose file dies; and docs with no api mounted,
# with two, and with the mount named.
#
# A compile that croaks leaves its package's routes registered, so every
# case is its own application, and the controller fixtures each case loads
# live under that application's namespace in a temporary library.

my $lib = File::Temp::tempdir(CLEANUP => 1);
sub spew { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; print $fh $s; close $fh }
sub fixture {
    my ($pkg, $name, $body) = @_;
    (my $dir = "$lib/$pkg/Controller") =~ s{::}{/}g;
    File::Path::make_path($dir);
    spew("$dir/$name.pm", "package ${pkg}::Controller::$name;\n$body");
}
unshift @INC, $lib;

my $n = 0;
sub compiles {
    my ($body, $pkg) = @_;
    $pkg //= 'CE' . ++$n;
    my $err = '';
    eval "package $pkg; use Punk; $body; $pkg->to_app" or $err = $@;
    return $err;
}

# ---- route targets ----------------------------------------------------------------
like(compiles(q{ get '/u' => undef }), qr/must be a coderef or 'Controller#method', got undef/, 'an undef target');
like(compiles(q{ get '/u' => 'nohash' }), qr/must be a coderef or 'Controller#method', got 'nohash'/, 'a bare word');
like(compiles(q{ get '/u' => 'Ctl#bad method' }), qr/got 'Ctl#bad method'/, 'a method with a space in it');
like(compiles(q{ get '/u' => 'Ctl#' }), qr/got 'Ctl#'/, 'an empty method');
like(compiles(q{ get '/u' => 'Missing#show' }), qr/names 'Missing#show' but CE\d+::Controller::Missing does not load: Can't locate/,
    'a controller with no file does not load');

fixture('CEDies', 'Dies', "die \"dies on load\\n\";\n");
like(compiles(q{ get '/u' => 'Dies#show' }, 'CEDies'), qr/names 'Dies#show' but CEDies::Controller::Dies does not load: dies on load/,
    'a controller that dies while loading');

fixture('CEHalf', 'Half', "sub other { \$_[0]->text('other') }\ndie \"half way\\n\";\n");
like(compiles(q{ get '/u' => 'Half#show' }, 'CEHalf'), qr/names 'Half#show' but CEHalf::Controller::Half does not load: half way/,
    'one that defined some subs before dying, asked for a method it did not reach');
fixture('CEHalf2', 'Half', "sub other { \$_[0]->text('other') }\ndie \"half way\\n\";\n");
is(compiles(q{ get '/u' => 'Half#other' }, 'CEHalf2'), '', 'but a method it did define resolves');

fixture('CEFine', 'Fine', "sub show { \$_[0]->text('fine') }\n1;\n");
like(compiles(q{ get '/u' => 'Fine#nope' }, 'CEFine'), qr/names 'Fine#nope' but CEFine::Controller::Fine has no method 'nope'/,
    'a controller that loads but has no such method');
fixture('CEFull', 'Fine', "sub show { \$_[0]->text('fine') }\n1;\n");
my $full = eval q{ package CEFull; use Punk; get '/u' => 'CEFull::Controller::Fine#show'; CEFull->to_app };
is($@, '', 'a controller named in full resolves');
is($full && hit($full, path => '/u')->[2][0], 'fine', 'and answers');
fixture('CEOut', 'Fine', "sub show { \$_[0]->text('fine') }\n1;\n");
like(compiles(q{ get '/u' => 'Elsewhere::Fine#show' }, 'CEOut'), qr/CEOut::Controller::Elsewhere::Fine does not load/,
    'a name from outside the namespace is looked for inside it');

# ---- models -------------------------------------------------------------------------
{
    package CEM2::Model::Bare;
    use Punk::Model;
    package main;
}
File::Path::make_path("$lib/CEM3/Model", "$lib/CEM1/Model");
spew("$lib/CEM1/Model/Plain.pm", "package CEM1::Model::Plain;\nsub new { bless {}, shift }\n1;\n");
spew("$lib/CEM3/Model/Broken.pm", "package CEM3::Model::Broken;\nuse Punk::Model;\ndie \"broken model\\n\";\n");
like(compiles(q{ model 'Plain' }, 'CEM1'), qr/model 'Plain' \(CEM1::Model::Plain\) does not use Punk::Model/, 'a model that is not a Punk::Model');
like(compiles(q{ model 'Bare' }, 'CEM2'), qr/model 'Bare' \(CEM2::Model::Bare\) declares no table/, 'a Punk::Model with no table');
like(compiles(q{ model 'Broken' }, 'CEM3'), qr/model 'Broken' \(CEM3::Model::Broken\) failed to load: broken model/, 'a model whose file dies');

# ---- docs -----------------------------------------------------------------------------
sub spec {
    my ($op) = @_;
    return {
        openapi => '3.1.0',
        info    => { title => 'Docs', version => '1' },
        paths   => { "/$op" => { get => { operationId => $op, responses => { 200 => { description => 'ok' } } } } },
    };
}
like(compiles(q{ docs '/docs' }), qr/docs needs an api mount \(none registered\)/, 'docs with no api');
like(compiles(q{ under('/one')->api(main::spec('one') => { handlers => { one => sub { [] } } }); under('/two')->api(main::spec('two') => { handlers => { two => sub { [] } } }); docs '/docs' }),
    qr/docs needs the mount named \(several apis are registered\)/, 'docs with two apis and no name');
SKIP: {
    skip 'Open::API::UI is not installed', 2 unless eval { require Open::API::UI; 1 };
    my $docs = eval q{ package CEDocs; use Punk; my $m = under('/one')->api(main::spec('one') => { handlers => { one => sub { [] } } }); under('/two')->api(main::spec('two') => { handlers => { two => sub { [] } } }); docs '/docs' => $m; CEDocs->to_app };
    is($@, '', 'docs naming the mount compiles with two apis');
    is($docs && hit($docs, path => '/docs')->[0], 200, 'and serves');
}

done_testing;
