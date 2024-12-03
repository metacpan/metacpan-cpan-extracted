use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use Alien::proj;

my $package_name = "PDL::Transform::Proj4";
my $lib_name = "Proj4";

my $ppfile = "proj4.pd";
my $package = [$ppfile, 'Proj4', $package_name];
my %hash = pdlpp_stdargs($package);
$hash{VERSION_FROM} = $ppfile;
$hash{LIBS}[0] .= ' ' . Alien::proj->libs;
$hash{INC}     .= ' ' . Alien::proj->cflags;
$hash{realclean} ||= { FILES => 'Proj4.xs' };
$hash{realclean}{FILES} .= ' _Inline';
$hash{PM}{'Demo.pm'} = '$(INST_LIB)/PDL/Demos/Proj4_demo.pm';
$hash{CONFIGURE_REQUIRES} = {
  'ExtUtils::MakeMaker' => 0,
  'PDL' => '2.094',
  'Alien::proj' => '1.29', # guarantee minimum PROJ 7.1 as need degree_output
};
$hash{PREREQ_PM} = {
  'PDL' => '2.094',
};
$hash{TEST_REQUIRES} = {
  'Test::More' => '0.88',
};
$hash{AUTHOR} = 'PerlDL Developers <pdl-general@lists.sourceforge.net>';

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble( $package ); };
WriteMakefile(%hash);
