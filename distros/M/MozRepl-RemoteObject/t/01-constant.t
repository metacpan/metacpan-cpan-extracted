#!perl -w
use strict;
use Test::More;

use MozRepl::RemoteObject;

my $repl;
my $ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge(
        #log => [qw[debug]],
    );
    1;
};
if (! $ok) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
} else {
    plan tests => 4;
};

# First, declare our "class" with a "constant"
my $obj = $repl->expr(<<JS);
    window.myclass = {
        SOME_CONSTANT: 42,
    };
JS

my $lived;
eval {
    my $val = $repl->constant('non.existing.class.SOME_CONSTANT');
    $lived = 1;
};
my $err = $@;
is $lived, undef, "Nonexisting constants raise an error";
like $err, '/MozRepl::RemoteObject: ReferenceError:/',
    "The raised error tells us that";


my $forty_two = $repl->constant('window.myclass.SOME_CONSTANT');
is $forty_two, 42, "We can retrieve a constant";

$obj->{SOME_CONSTANT} = 43;

$forty_two = $repl->constant('window.myclass.SOME_CONSTANT');
is $forty_two, 42, "Constants are cached, even if they change on the JS side";
