use strict;
use warnings;
use File::Spec;
use Test::More;

use lib (-d 't' ? File::Spec->catdir(qw(t lib)) : 'lib' );
use Queue::Q::Test;
use Queue::Q::TestNaiveFIFO;

use Queue::Q::NaiveFIFO::Perl;

my $q = Queue::Q::NaiveFIFO::Perl->new();

isa_ok($q, "Queue::Q::NaiveFIFO");
isa_ok($q, "Queue::Q::NaiveFIFO::Perl");

Queue::Q::TestNaiveFIFO::test_naive_fifo($q);

done_testing();
