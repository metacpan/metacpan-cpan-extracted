#!perl -w
use strict;
use Test::More;

use MozRepl::RemoteObject;

my $repl;
my $ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge(
        #log => [qw[debug info]],
    );
    1;
};
if (! $ok) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
} else {
    plan tests => 10;
};

# create a nested object
sub genObj {
    my ($repl) = @_;
    my $rn = $repl->name;
    my $obj = $repl->expr(<<JS)
(function(repl, val) {
    var res = {};
    res.foo  = function() { return "foo" };
    res.__id = function() { return "my JS id"  };
    res.__invoke = function() { return "my JS invoke"  };
    res.id   = function(p) { return p };
    return res
})($rn)
JS
}

my $obj = genObj($repl);
isa_ok $obj, 'MozRepl::RemoteObject::Instance';

my $res = $obj->__invoke('foo');
is $res, 'foo', "Can __invoke 'foo'";

$res = $obj->foo();
is $res, 'foo', "Can call foo()";

$res = $obj->__invoke('__id');
is $res, 'my JS id', "Can __invoke '__id'()";

$res = $obj->__invoke('__invoke');
is $res, 'my JS invoke', "Can __invoke '__invoke'()";

$res = $obj->id('123');
is $res, 123, "Can pass numerical parameters";

$res = $obj->id(123);
is $res, 123, "Can pass numerical parameters";

$res = $obj->id('abc');
is $res, 'abc', "Can pass alphanumerical parameters";

$res = $obj->id($obj);

ok $res == $obj, "Can pass MozRepl::RemoteObject::Instance parameters";

my $js = <<'JS';
function(val) {
    var res = {};
    res.foo  = function() { return "foo" };
    res.__id = function() { return "my JS id"  };
    res.__invoke = function() { return "my JS invoke"  };
    res.id   = function(p) { return p };
    return res
}
JS

my $fn  = $repl->declare($js);
my $fn2 = $repl->declare($js);
ok $fn == $fn2, "Function declarations get cached";
