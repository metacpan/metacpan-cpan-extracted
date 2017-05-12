#!perl -w
use strict;
use Test::More;

use MozRepl::RemoteObject;

my $repl;
my $ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge(
        #log => ['debug'],
        use_queue => 1,
        #max_queue_size => 1000,
    );
    1;
};
if (! $ok) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
} else {
    plan tests => 4;
};

# Number of callbacks
my $callbacks = 10000;
my $start = time;

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

my $obj = genObj($repl);
isa_ok $obj, 'MozRepl::RemoteObject::Instance';

my $called = 0;
my @events;
$obj->{oncommand} = sub {
    $called++;
    push @events, @_;
};
ok 1, "Stored callback";

my $trigger_command = $repl->declare(<<JS);
    function(c,o,m) {
        for( var i=0;i<c;i++ ){
            o.oncommand(m);
        };
    };
JS

my $setup_roundtrips = $repl->{stats}->{roundtrip};
$trigger_command->($callbacks,$obj,'from_js');
is $called, $callbacks, "We got called $callbacks times";

$repl->poll; # flush the queue
my $taken = time - $start;
$taken ||= 1;

# 2 is the magic number of roundtrips needed for triggering the callback
# We have some additional overhead based on max_queue_size, so let's be generous
# and allow for 10%
cmp_ok $repl->{stats}->{roundtrip}-$setup_roundtrips, '<', $callbacks*1.1+2,
    "Callback overhead is about 1 roundtrip per triggered callback";

use Data::Dumper;
diag Dumper $repl->{stats};

diag sprintf "%0.2f iterations/s", $repl->{stats}->{roundtrip} / $taken