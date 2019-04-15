use strict;
use warnings;
use ExtUtils::MakeMaker;

our ($GSL_includes, $GSL_libs); 
my @pack = (['gsl_sf_hyperg.pd', qw(HYPERG PDLA::GSLSF::HYPERG)]);
my %hash = pdlpp_stdargs(@pack);
$hash{INC} .= ' '.$GSL_includes;
push @{$hash{LIBS}},$GSL_libs;

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };
WriteMakefile(%hash);
