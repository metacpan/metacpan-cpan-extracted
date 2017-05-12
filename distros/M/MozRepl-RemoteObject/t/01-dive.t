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
    plan tests => 6;
};

# create two remote objects
sub genObj {
    my ($repl,$val) = @_;
    my $rn = $repl->name;
    my $obj = $repl->expr(<<JS)
(function(repl, val) {
    return { bar: { baz: { value: val } } };
})($rn, "$val")
JS
}

my $foo = genObj($repl, 'deep');
isa_ok $foo, 'MozRepl::RemoteObject::Instance';

my $baz = $foo->__dive(qw[bar baz]);
isa_ok $baz, 'MozRepl::RemoteObject::Instance', "Diving to an object works";
is $baz->{value}, 'deep', "Diving to an object returns the correct object";

my $val = $foo->__dive(qw[bar baz value]);
is $val, 'deep', "Diving to a value works";

$val = eval { $foo->__dive(qw[bar flirble]); 1 };
my $err = $@;
is $val, undef, "Diving into a nonexisting property fails";
like $err, '/bar\.flirble/', "Error message mentions last valid property and failed property";
