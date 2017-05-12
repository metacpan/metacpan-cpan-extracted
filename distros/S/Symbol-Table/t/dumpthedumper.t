#!/usr/local/bin/perl

use Test::More tests => 3;
BEGIN { use_ok('Symbol::Table') };

##################################################################
# use symbol table object to override the Dumper 
# subroutine in Data::Dumper
# first confirm it works normally as expected.
##################################################################
use Data::Dumper;

my $test_var = [ qw ( alpha bravo charlie delta ) ];

my $str = Dumper $test_var;

my $normal =<<'NORMAL';
$VAR1 = [
          'alpha',
          'bravo',
          'charlie',
          'delta'
        ];
NORMAL
;

is($str,$normal,"Confirm Data::Dumper works as expected");

##################################################################
# now override the Data::Dumper subroutine.
##################################################################

my $st=Symbol::Table->New('CODE');

$st->{Dumper}= sub 
	{return "Dumper cant come to the phone now";};


my $override = Dumper $test_var;

my $exp_override = 'Dumper cant come to the phone now';

is($override,$exp_override, "override a subroutine");


