use strict;
use warnings;
use ExtUtils::MakeMaker;

my @pack = (["slices.pd", qw(Slices PDLA::Slices)]);

my %hash =pdlpp_stdargs_int(@pack);

undef &MY::postamble; # suppress warning
*MY::postamble = sub {
	pdlpp_postamble_int(@pack);
};

WriteMakefile(%hash);
