use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDLA::Core::Dev;

my $package_name = "PDLA::GIS::Proj";
my $lib_name = "Proj";

use Alien::Proj4;

my $libflags = join ' ',  Alien::Proj4->libs;
my $incflags = Alien::Proj4->cflags;

my $ppfile = "Proj.pd";
my $package = [$ppfile, 'Proj', $package_name];
my %hash = pdlpp_stdargs($package);
$hash{VERSION_FROM} = $ppfile;
#$hash{TYPEMAPS} = [&PDLA_TYPEMAP()];
$hash{LIBS} = [ $libflags ];
$hash{INC} = PDLA_INCLUDE() . " $incflags";

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble( $package ); };

WriteMakefile(%hash);
