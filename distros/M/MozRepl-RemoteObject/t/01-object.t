#!perl -w
use strict;
use Test::More;

use MozRepl::RemoteObject;

diag "--- Loading object functionality into repl\n";

my $repl;
my $ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge(
    #log => ['debug'],
    );
    1;
};
if (! $ok) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
} else {
    plan tests => 6;
};

# create a nested object
sub genObj {
    my ($repl,$val) = @_;
    my $rn = $repl->name;
    my $obj = $repl->expr(<<JS)
(function(repl, val) {
    return { "bar": [ 'baz', { "value": val } ] };
})($rn, "$val")
JS
}

my $foo = genObj($repl, 'deep');
isa_ok $foo, 'MozRepl::RemoteObject::Instance';

my $bar = genObj($repl, 'deep2');
isa_ok $bar, 'MozRepl::RemoteObject::Instance';

my $lives = eval {
    $foo->{ bar } = $bar;
    1;
};
my $err = $@;
ok $lives, "We survive the assignment";
is $@, '', "No error";

is $foo->{ bar }->{ bar }->[1]->{value}, 'deep2', "Assignment happened";

my $destroyed;
$foo->__on_destroy(sub{ $destroyed++});
undef $foo;
is $destroyed, 1, "Object destruction callback was invoked";