#!/usr/bin/env perl 

use strict;
use warnings;
BEGIN {
    push @INC, ('blib/lib', 'blib/arch');
}
use lib '../lib';
use blib;

use Parse::STDF;
use Test::More tests => 5;
note 'Testing Parse::STDF functions';

my $s = Parse::STDF->new("data/test.stdf"); 

while ( $s->get_record() )
{ 
  if ( $s->recname() eq "RDR" )
  {
    my $rdr = $s->rdr();
	my $a_ref = Parse::STDF::xU2_array_ref($rdr->{RTST_BIN}, $rdr->{NUM_BINS});
    ok ( @{$a_ref} == $rdr->{NUM_BINS} , 'xU2_array_ref');
  }

  if ( $s->recname() eq "SDR" )
  {
    my $sdr = $s->sdr();
	my $a_ref = Parse::STDF::xU1_array_ref($sdr->{SITE_NUM}, $sdr->{SITE_CNT});
    ok ( @{$a_ref} == $sdr->{SITE_CNT} , 'xU1_array_ref');
  }

  if ( $s->recname() eq "MPR" )
  {
    my $mpr = $s->mpr();
	my $a_ref = Parse::STDF::xR4_array_ref($mpr->{RTN_RSLT}, $mpr->{RSLT_CNT});
    ok ( @{$a_ref} == $mpr->{RSLT_CNT} , 'xR4_array_ref');
	$a_ref = Parse::STDF::xN1_array_ref($mpr->{RTN_STAT}, $mpr->{RTN_ICNT});
    ok ( @{$a_ref} == $mpr->{RTN_ICNT} , 'xN1_array_ref');
  }

  if ( $s->recname() eq "PLR" )
  {
    my $plr = $s->plr();
	my $a_ref = Parse::STDF::xCn_array_ref($plr->{PGM_CHAR}, $plr->{GRP_CNT});
    ok ( @{$a_ref} == $plr->{GRP_CNT} , 'xCn_array_ref');
  }
}

