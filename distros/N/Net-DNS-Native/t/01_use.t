use strict;
use Test::More;
use_ok('Net::DNS::Native');

my $dns = Net::DNS::Native->new;
isa_ok($dns, 'Net::DNS::Native');

done_testing;
