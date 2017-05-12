#!perl -w
use strict;
use Test::More;
use MozRepl::RemoteObject;

my $repl;
my $ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge();
    1;
};
if (! $ok) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
} else {
    plan tests => 9;
};

my $foo = $repl->declare(<<'JS')->();
    function () { return { val: "foo" } }
JS
isa_ok $foo, 'MozRepl::RemoteObject::Instance', "We hold onto a remote object in the first bridge";

my $second;
$ok = eval {
    $second = MozRepl::RemoteObject->install_bridge(
        #log => [qw[debug]],
    );
    1;
};

ok $ok, "We can create a second bridge instance"
    or diag $@;

my $bar = $repl->declare(<<'JS')->();
    function () { return { val: "bar" } }
JS
isa_ok $bar, 'MozRepl::RemoteObject::Instance', "We hold onto a remote object in the second bridge";

my $res;
$ok = eval {
    $res = $foo->{val};
    1
};
my $err = $@;
ok $ok, "We can still access a value from the first bridge instance";
is $@, '', "... no error was raised";
is $res, 'foo', "... and it's the correct value";

undef $res;
$ok = eval {
    $res = $bar->{val};
    1
};
$err = $@;
ok $ok, "We can still access a value from the second bridge instance";
is $@, '', "... no error was raised";
is $res, 'bar', "... and it's the correct value";