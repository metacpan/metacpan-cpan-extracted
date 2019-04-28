use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDLA::Core::Dev;

our ($GSL_includes, $GSL_libs); 
my @pack = (['gsl_sf_gegenbauer.pd', qw(GEGENBAUER PDLA::GSLSF::GEGENBAUER)]);
my %hash = pdlpp_stdargs(@pack);
$hash{INC} .= ' '.$GSL_includes;
push @{$hash{LIBS}},$GSL_libs;

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };
WriteMakefile(%hash);
