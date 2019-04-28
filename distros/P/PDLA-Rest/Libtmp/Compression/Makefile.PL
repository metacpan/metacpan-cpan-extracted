use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDLA::Core::Dev;

my @pack = (["compression.pd", qw(Compression PDLA::Compression)]);
my %hash = pdlpp_stdargs(@pack);

# Add genpp rule
undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };

WriteMakefile( %hash );
