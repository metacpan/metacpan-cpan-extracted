use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDLA::Core::Dev;

my @pack = (["fft.pd", qw(FFT PDLA::FFT)]);
my %hash = pdlpp_stdargs(@pack);
$hash{OBJECT} .= ' fftn$(OBJ_EXT)';
$hash{DEFINE} .= ' -DFFT_FLOAT';
$hash{LIBS} = ['-lm'] unless $^O =~ /MSWin/;

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };

WriteMakefile(%hash);
