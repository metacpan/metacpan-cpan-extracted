use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Net::OpenStack::Client;

my $cl = Net::OpenStack::Client->new();
isa_ok($cl, 'Net::OpenStack::Client', 'Net::OpenStack::Client instance created');

isa_ok($cl->{rc}, 'REST::Client', 'client has REST::Client instance in rc attribute');

done_testing;
