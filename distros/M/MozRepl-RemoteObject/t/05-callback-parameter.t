#!perl -w
use strict;
use Test::More;

use MozRepl::RemoteObject;

my $repl;
my $ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge(
        #log => ['debug'],
        use_queue => 1,
    );
    1;
};
if (! $ok) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
} else {
    plan tests => 1;
};

my $fetch_foo = $repl->declare(<<JS);
function(e) {
    return e.foo;
}
JS

sub genObj {
    my ($repl) = @_;
    my $rn = $repl->name;
    my $obj = $repl->expr(<<JS)
(function() {
    var res = {};
    res.foo = "bar";
    res.baz = "flirble";
    return res
})()
JS
}

my $apply = $repl->declare(<<JS);
function( cont, item ) {
    return cont(item)
};
JS

my $obj = genObj($repl);

is $apply->($fetch_foo, $obj), 'bar', "We can apply a JS function to a JS object";
