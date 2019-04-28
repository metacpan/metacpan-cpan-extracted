use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDLA::Core::Dev;

our ($GSL_includes, $GSL_libs); 
my @pack = (['gsl_sf_pow_int.pd', qw(POW_INT PDLA::GSLSF::POW_INT)]);
my %hash = pdlpp_stdargs(@pack);
$hash{INC} .= ' '.$GSL_includes;
push @{$hash{LIBS}},$GSL_libs;

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };
WriteMakefile(%hash);
