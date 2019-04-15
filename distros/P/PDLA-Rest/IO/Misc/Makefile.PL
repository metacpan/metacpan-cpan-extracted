use strict;
use warnings;
use ExtUtils::MakeMaker;

my @pack = (["misc.pd", qw(Misc PDLA::IO::Misc)]);

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };

WriteMakefile(
 pdlpp_stdargs(@pack)
);
