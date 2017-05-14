#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Net::UPS::Package;

my @data = (
    [{},{},'no sizes, nothing in hash'],
    [{length=>10},
     {UnitOfMeasurement=>{Code=>ignore()},Length=>10},
     'length only'],
    [{length=>10,width=>20},
     {UnitOfMeasurement=>{Code=>ignore()},Length=>10,Width=>20},
     'length & width'],
    [{length=>10,width=>20,height=>15},
     {UnitOfMeasurement=>{Code=>ignore()},Length=>10,Width=>20,Height=>15},
     'all sizes']
);

for my $d (@data) {
    my ($args,$cmp,$comment) = @$d;

    if (%$cmp) { $cmp={Dimensions=>$cmp} }

    my $p = Net::UPS::Package->new(weight=>10,%$args);

    cmp_deeply($p->as_hash,
               {
                   Package => {
                       PackagingType => { Code => ignore() },
                       DimensionalWeight => { UnitOfMeasurement => { Code => ignore() } },
                       PackageWeight => {
                           UnitOfMeasurement => { Code => ignore() },
                           Weight => 10,
                       },
                       %$cmp,
                   },
               },
               $comment,
           );
}

done_testing();
