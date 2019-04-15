use strict;
use warnings;
use ExtUtils::MakeMaker;

my @pack = (["transform.pd", qw(Transform PDLA::Transform)]);
my %hash = pdlpp_stdargs(@pack);
$hash{DIR} = ['Cartography', 'Proj4'];

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };

WriteMakefile( %hash );
