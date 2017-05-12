#!/usr/bin/perl
#
# $RCSfile: sdict-tools.plx,v $
# $Author: swaj $
# $Revision: 1.12.2.1 $
#
# Sdict Convertion Tools
#

use 5.008;
use strict;
use warnings;


BEGIN {
  $_=$0;
  s|^(.+)/.*|$1|;
  push @INC, ($_, "$_/lib", "$_/../lib", "$_/..") ;
};


use Sdict;

$Sdict::debug = 1;

my $sd = Sdict->new;

$sd->parse_args;

$sd->convert;




__END__
