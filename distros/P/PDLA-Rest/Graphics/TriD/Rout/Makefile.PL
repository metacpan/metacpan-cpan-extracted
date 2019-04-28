use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDLA::Core::Dev;

my @pack = (["rout.pd", qw(Rout PDLA::Graphics::TriD::Rout)]);
my %hash = pdlpp_stdargs(@pack);
$hash{LIBS} = ['-lm'];

undef &MY::postamble; # suppress warning
*MY::postamble = sub {
	pdlpp_postamble(@pack);
};

WriteMakefile(%hash);
