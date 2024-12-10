use strict;
use warnings;
use ExtUtils::MakeMaker;

my @pack = (["gaussian.pd", qw(Gaussian PDL::Fit::Gaussian)]);
my %hash = pdlpp_stdargs(@pack);
$hash{OBJECT} .= ' gauss$(OBJ_EXT)';
$hash{LIBS} = ['-lm'] unless $^O =~ /MSWin/;

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };

WriteMakefile(%hash);
