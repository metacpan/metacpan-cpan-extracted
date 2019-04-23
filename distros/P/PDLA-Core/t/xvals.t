use strict;
use warnings;

use Test::More tests => 4;
use PDLA::LiteF;
kill 'INT',$$ if $ENV{UNDER_DEBUGGER}; # Useful for debugging.


my $a0 = zeroes(3,2);
# $a0->doflow();

 note $a0;

my $a1 = $a0->slice('(1)');

 note $a1;

# $a0->dump(); $a1->dump();

# $a1->dump();

$a1 += 4;

# $a1->dump();

 note $a1;

my $dummy = PDLA::Core::new_or_inplace($a0);
note $dummy;
my $dummy2 = $dummy->xchg(0,0);
note $dummy2;
# $dummy2->dump();
# $dummy->dump();
PDLA::Primitive::axisvalues($dummy2);
# $dummy2->dump();
# $dummy->dump();
note $dummy2;
note $dummy;



# $a1->dump();

# $a0->dump(); $a1->dump();

# note $a1;

# note $a0;

# note $a1;

my $pa = xvals $a0;

note $pa;

is($pa->at(0,0), 0, "xvals 0,0 == 0");
is($pa->at(1,0), 1, "xvals 1,0 == 1");
is($pa->at(2,0), 2, "xvals 2,0 == 2");
is($pa->at(1,1), 1, "xvals 1,1 == 1");
