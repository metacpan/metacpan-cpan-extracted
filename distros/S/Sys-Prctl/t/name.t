use strict;
use warnings;

use Test::More tests => 7;

use Sys::Prctl qw(prctl_name);


print "pid: $$, $0\n";

#is(prctl_name(), "perl", "Could get process name"); # TODO: We don't know if it's perl that calls us, could be perl5.10.0
is(prctl_name("test"), 1, "Could set process name");
is(prctl_name(), "test", "Could get new process name");
is(prctl_name("a" x 30), 1, "Could set oversized process name");
is(prctl_name(), "a" x 15, "Could get oversized process name");

my $prctl = new Sys::Prctl();
is($prctl->name(), "a" x 15, "Could get oversized process name with object interface");
is($prctl->name("Simple"), 1, "Could set simple process name with object interface");
is($prctl->name(), "Simple", "Could set simple process name with object interface");

