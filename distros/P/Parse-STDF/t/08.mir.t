#!/usr/bin/env perl 

use strict;
use warnings;
BEGIN {
    push @INC, ('blib/lib', 'blib/arch');
}
use lib '../lib';
use blib;

use Parse::STDF;
use Test::More tests => 3;
note 'Testing Parse::STDF->mir()';

my $s = Parse::STDF->new("data/test.stdf"); 

while ( $s->get_record() ) 
{
  if ( $s->recname() eq "MIR" )
  {
    ok ( 1, 'MIR record found in data/test.stdf');
	my $mir = $s->mir();
	ok ( defined($mir), 'MIR object defined');
	ok ( $mir->{LOT_ID} eq "LOT_ID", 'LOT_ID == LOT_ID');
  }
}
