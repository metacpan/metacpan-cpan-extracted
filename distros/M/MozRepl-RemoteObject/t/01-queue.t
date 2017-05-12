#!perl -w
use strict;
use Test::More;

use MozRepl::RemoteObject;

diag "--- Loading object functionality into repl\n";

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

undef $foo; # queues the destructor call

ok @{ $repl->queue } > 0, "We queued some commands";

diag $_ for @{ $repl->queue };

$repl->poll;

ok @{ $repl->queue } == 0, "We flushed the queue";
