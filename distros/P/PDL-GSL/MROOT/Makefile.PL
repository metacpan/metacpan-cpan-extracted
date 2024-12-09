use strict;
use warnings;
use ExtUtils::MakeMaker;

our ($GSL_includes, $GSL_libs); 

my @pack = (["gsl_mroot.pd", qw(MROOT PDL::GSL::MROOT), undef, 1]);
my %hash = pdlpp_stdargs(@pack);

$hash{INC} .= " $GSL_includes";
push @{$hash{LIBS}},$GSL_libs;
$hash{OBJECT} .= ' FUNC$(OBJ_EXT)';

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };
WriteMakefile(%hash, NO_MYMETA=>1);
