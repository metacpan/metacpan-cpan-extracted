use strict;
use warnings;
use File::Spec;
use Test::More;

use lib (-d 't' ? File::Spec->catdir(qw(t lib)) : 'lib' );
use Queue::Q::Test;
use Queue::Q::TestClaimFIFO;

use Queue::Q::ClaimFIFO::Perl;

my $q = Queue::Q::ClaimFIFO::Perl->new();
isa_ok($q, "Queue::Q::ClaimFIFO");
isa_ok($q, "Queue::Q::ClaimFIFO::Perl");

Queue::Q::TestClaimFIFO::test_claim_fifo($q);

done_testing();
