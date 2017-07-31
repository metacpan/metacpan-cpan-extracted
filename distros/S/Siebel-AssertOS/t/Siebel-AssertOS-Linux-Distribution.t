use warnings;
use strict;
use Siebel::AssertOS::Linux::Distribution;
use Test::More tests => 1;

can_ok(
    'Siebel::AssertOS::Linux::Distribution',
    qw( distribution_name distribution_version )
);
