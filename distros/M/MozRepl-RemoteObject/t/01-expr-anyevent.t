#!perl -w
use strict;
use Test::More;

use MozRepl::RemoteObject;

my $ok = eval {
    require MozRepl::AnyEvent;
    1;
};
my $err = $@;

my $repl;
$ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge(
        #repl => $arepl,
        repl_class => 'MozRepl::AnyEvent',
    );
    1;
};
if (! $ok) {
    $err ||= $@;
    plan skip_all => "Couldn't connect to Firefix: $err";
} else {
    plan tests => 5;
};

isa_ok $repl->repl, 'MozRepl::AnyEvent', 'We installed the class we passed in';

my $four = $repl->expr(<<JS);
    2+2
JS

is $four, 4, "Addition in Javascript works";

my $wrapped_repl = $repl->expr(<<JS);
    repl
JS

my $repl_id = $wrapped_repl->__id;
my $identity = $repl->expr(<<JS);
    repl === repl.getLink($repl_id)
JS

ok $identity, "Object identity in Javascript works";

my $adder = $repl->expr(<<JS);
    f=function(a,b) { return a+b };f
JS
isa_ok $adder, 'MozRepl::RemoteObject::Instance';

my $five = $adder->(2,3);
is $five, 5, "Anonymous functions in Javascript work as well";
