# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan); 

use Oracle::SQL;
my $class = "Oracle::SQL";
my $self  = bless {}, $class;
my $obj = $self->new; 

isa_ok($obj, $class);

my @md = (@Oracle::SQL::EXPORT_OK,@Oracle::SQL::IMPORT_OK);
foreach my $m (@md) {
    ok($obj->can($m), "$class->can('$m')");
}

1;

