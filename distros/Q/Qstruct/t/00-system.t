use Qstruct;

use strict;

use Test::More tests => 1;


my $little_endian = pack("I!", 1) =~ /^\x01/;
my $int_size = length(pack("I!", 0));
my $long_size = length(pack("L!", 0));
my $pointer_size = length(pack("P", 0));

my $system_info = ($little_endian ? 'little' : 'big') . " endian, ILP: $int_size, $long_size, $pointer_size";
diag("SYSTEM: $^O - $system_info");

my $uname = `uname -a` || "failed: $!";
diag("SYSTEM: uname -a: $uname");

ok(($int_size == 4 && $long_size == 4 && $pointer_size == 4) ||
   ($int_size == 4 && $long_size == 8 && $pointer_size == 8) ||
   ($int_size == 4 && $long_size == 4 && $pointer_size == 8),
   'only ILP32, LP64, and LLP64 are supported');
