#!/bin/env perl

use lib '../lib','lib';

use strict;
use warnings;

use String::BooleanSimple ':all';

use Test::More tests => 78;


my @true = qw(true yes active enabled on y ok positive 1 2 3 4 5 6 7 8 9);

my @false = qw(false no inactive disabled off n negative 0);
push @false,"not ok";


foreach my $true (@true) {

  is( is_true($true) , 1, "is_true - String is \'$true\'" );
  is( is_false($true) , 0, "is_false - String is \'$true\'" );
  is( boolean($true) , 1, "boolean - String is \'$true\'" );

}

foreach my $false (@false) {

  is( is_false($false) , 1, "is_false - String is \'$false\'" );
  is( is_true($false) , 0, "is_true - String is \'$false\'" );
  is( boolean($false) , 0, "boolean - String is \'$false\'" );

}

done_testing();

