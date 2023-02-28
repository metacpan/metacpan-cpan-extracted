use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use Prima::Config;
use Config;

my @package = qw(utils.pd Utils PDL::Drawing::Prima::Utils);
my %hash = pdlpp_stdargs(\@package);

undef &MY::postamble;
*MY::postamble = sub { pdlpp_postamble(\@package) };

WriteMakefile(
  %hash,
  NO_MYMETA => 1,
);
