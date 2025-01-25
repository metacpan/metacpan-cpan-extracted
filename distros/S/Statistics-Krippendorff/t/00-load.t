#!perl
use 5.006;
use strict;
use warnings;
use Test2::V0;

plan tests => 1;

use Statistics::Krippendorff ();

my $sk = 'Statistics::Krippendorff'->new(units => [[1,2]]);
ok $sk, 'Instantiates';

diag( "Testing Statistics::Krippendorff $Statistics::Krippendorff::VERSION, Perl $], $^X" );
