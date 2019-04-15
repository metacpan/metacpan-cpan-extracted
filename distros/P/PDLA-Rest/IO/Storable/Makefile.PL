use strict;
use warnings;
use ExtUtils::MakeMaker;

my @pack = (["storable.pd", qw(Storable PDLA::IO::Storable)]);

my %hash = pdlpp_stdargs(@pack);
# $hash{'OPTIMIZE'}  = '-g'; # If you want to debug, uncomment this.
$hash{'VERSION'}  = '0.5';

# Add genpp rule
undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };

WriteMakefile(%hash);
