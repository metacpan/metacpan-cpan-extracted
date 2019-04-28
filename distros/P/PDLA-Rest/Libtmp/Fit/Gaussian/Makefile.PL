use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDLA::Core::Dev;

my @pack = (["gaussian.pd", qw(Gaussian PDLA::Fit::Gaussian)]);
my %hash = pdlpp_stdargs(@pack);
$hash{OBJECT} .= ' ';
$hash{DEFINE} .= ' ';
$hash{LIBS} = ['-lm'] unless $^O =~ /MSWin/;

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };

WriteMakefile(%hash);
