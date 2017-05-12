# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan); 

use Oracle::Schema;
my $class = 'Oracle::Schema';
my $obj = Oracle::Schema->new; 

isa_ok($obj, $class);

my @md = (@Oracle::Schema::EXPORT_OK,@Oracle::Schema::IMPORT_OK);
foreach my $m (@md) {
    ok($obj->can($m), "$class->can('$m')");
}

1;

