# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan); 

use Oracle::Trigger;
my $class = 'Oracle::Trigger';
my $obj = Oracle::Trigger->new; 

isa_ok($obj, $class);

my @md = (@Oracle::Trigger::EXPORT_OK,@Oracle::Trigger::IMPORT_OK);
foreach my $m (@md) {
    ok($obj->can($m), "$class->can('$m')");
}

1;

