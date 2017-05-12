#!/usr/bin/perl
use strict;
use warnings;
use PDLA;
use Inline qw{Pdlapp};

my $v = pdl(1)->pdl_core_version()->at(0);

print <<"EOPM";
package PDLA::Config::Debian;
our \$pdl_core_version = $v;
1;
EOPM

__DATA__

__Pdlapp__

pp_def('pdl_core_version',
	Pars => 'dummy(); int [o] pcv();',
	Code => '$pcv() = PDLA_CORE_VERSION;');

pp_done;
