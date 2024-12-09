use strict;
use warnings;
use ExtUtils::MakeMaker;

our ($GSL_includes, $GSL_libs); 

my @pack = (["gsl_random.pd", qw(RNG PDL::GSL::RNG), undef, 1]);
my %hash = pdlpp_stdargs(@pack);

$hash{INC} .= " $GSL_includes";
push @{$hash{LIBS}},$GSL_libs;
$hash{PM}{'Demo.pm'} = '$(INST_LIB)/PDL/Demos/GSL_RNG.pm';

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };

WriteMakefile(%hash, NO_MYMETA=>1);
