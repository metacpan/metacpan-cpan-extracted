use strict;
use warnings;

use Test::More tests => 1;

use Queue::Q;
use Queue::Q::NaiveFIFO;
use Queue::Q::ClaimFIFO;

use Queue::Q::NaiveFIFO::Redis;
use Queue::Q::ClaimFIFO::Redis;

use Queue::Q::NaiveFIFO::Perl;
use Queue::Q::ClaimFIFO::Perl;

use Queue::Q::DistFIFO;

pass("Alive");

