use strict;
use warnings;
use ExtUtils::MakeMaker;

my @pack = (["pnm.pd", qw(Pnm PDLA::IO::Pnm)]);

my %hash = pdlpp_stdargs(@pack);
$hash{'PM'}->{'Pic.pm'} = '$(INST_LIBDIR)/Pic.pm';

# Add genpp rule
undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };

WriteMakefile(%hash);
