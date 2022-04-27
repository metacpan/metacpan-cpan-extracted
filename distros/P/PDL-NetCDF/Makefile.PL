use strict;
use warnings;
use PDL::Core::Dev;            # Pick up development utilities
use ExtUtils::MakeMaker;
use Devel::CheckLib qw(check_lib);

check_lib(
  header => 'netcdf.h', lib => 'netcdf',
) or die "Cannot find netcdf library. Please install NetCDF.";

# Check if compiled under gcc/Linux.  In which case, define bool for the compiler
my $define_bool = '';
if ($^O =~ /linux/) {
  $define_bool = '-Dbool=int';
  print "Defining bool=int (linux seems to need this)\n";
}

my $package = [qw(netcdf.pd NetCDF PDL::NetCDF)];
my %hash = pdlpp_stdargs($package);
my %more_items = (
  AUTHOR       => 'Douglas Hunt (dhunt@ucar.edu)',
  PREREQ_PM => {
    'PDL' => '2.019',
  },
  CONFIGURE_REQUIRES => {
    'Devel::CheckLib' => '1.14',
    'ExtUtils::MakeMaker' => '6.64', # TEST_REQUIRES
    'PDL' => '2.019',
  },
  BUILD_REQUIRES => {
    'Devel::CheckLib' => '1.14',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88', # done_testing
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      bugtracker  => {web=>'https://github.com/PDLPorters/PDL-NetCDF/issues'},
      repository  => {
        url => 'git://github.com/PDLPorters/PDL-NetCDF.git',
        type => 'git',
        web => 'https://github.com/PDLPorters/PDL-NetCDF',
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
  },
);
%hash = (%hash, %more_items);
$hash{INC} .= " $define_bool" if $define_bool;
$hash{LIBS}[0] .= " -lnetcdf";
WriteMakefile(%hash);

sub MY::postamble { pdlpp_postamble($package); }
