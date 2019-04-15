use strict;
use warnings;
use ExtUtils::MakeMaker;

my @pack = (["imagend.pd", qw(ImageND PDLA::ImageND)]);

# Add genpp rule
undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };

WriteMakefile( pdlpp_stdargs(@pack) );
