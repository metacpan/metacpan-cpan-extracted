#!/usr/bin/perl
#
# $RCSfile: dctinfo.plx,v $
# $Author: swaj $
# $Revision: 1.3.2.1 $
#

use 5.008;
use strict;
no warnings;


BEGIN {
  $_=$0;
  s|^(.+)/.*|$1|;
  push @INC, ($_, "$_/lib", "$_/../lib", "$_/..") ;
};


my $file = shift;
die "Usage: $0 file.dct\n" unless defined ($file);
open (F, "<$file") or die "Can't open file '$file' :$!\n"; close F;

$file = "--input-file=$file";

@ARGV = ( $file, '--printinfo', '--fool-terminal' );

use Sdict;
$Sdict::debug = 0;

my $sd = Sdict->new;

$sd->parse_args;

$sd->print_dct_info;


exit 0;



__END__
