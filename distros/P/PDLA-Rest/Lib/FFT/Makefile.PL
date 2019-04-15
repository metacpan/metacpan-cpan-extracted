use strict;
use warnings;
use ExtUtils::MakeMaker;

my @pack = (["fft.pd", qw(FFT PDLA::FFT)]);
my %hash = pdlpp_stdargs(@pack);
$hash{OBJECT} .= ' fftn.o';
$hash{DEFINE} .= ' -DFFT_FLOAT';
$hash{LIBS} = ['-lm'] unless $^O =~ /MSWin/;

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };

WriteMakefile(%hash);
