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
    plan tests => 3;
};

# create two remote objects
sub genObj {
    my ($repl,$val) = @_;
    my $rn = $repl->repl->repl;
    my $obj = $repl->expr(<<JS)
(function(repl, val) {
    return { value: val };
})($rn, "$val")
JS
}

my $foo = genObj($repl, 'foo');
isa_ok $foo, 'MozRepl::RemoteObject::Instance';
my $bar = genObj($repl, 'bar');
isa_ok $bar, 'MozRepl::RemoteObject::Instance';

my $foo_id = $foo->__id;

$bar->__release_action(<<JS);
    repl.getLink($foo_id)['value'] = "bar has gone";
JS

undef $bar;

is $foo->{value}, 'bar has gone', "JS-Release action works";