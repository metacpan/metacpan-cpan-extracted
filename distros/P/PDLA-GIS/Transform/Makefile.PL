use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDLA::Core::Dev;

my $package_name = "PDLA::Transform::Proj4";
my $lib_name = "Proj4";

use Alien::Proj4;

my $libflags = join ' ',  Alien::Proj4->libs;
my $incflags = Alien::Proj4->cflags;

my $ppfile = "Proj4.pd";
my $package = [$ppfile, 'Proj4', $package_name];
my %hash = pdlpp_stdargs($package);
$hash{VERSION_FROM} = $ppfile;
#$hash{TYPEMAPS} = [&PDLA_TYPEMAP()];
$hash{LIBS} = [ $libflags ];
$hash{INC} = PDLA_INCLUDE() . " $incflags";
$hash{realclean} = { FILES => '' } unless $hash{realclean};
$hash{realclean}{FILES} .= ' _Inline';

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble( $package ); };
WriteMakefile(%hash);
