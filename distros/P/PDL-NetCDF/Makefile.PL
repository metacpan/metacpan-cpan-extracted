use strict;
use warnings;
use PDL::Core::Dev;            # Pick up development utilities
use ExtUtils::MakeMaker;
use Devel::CheckLib qw(check_lib);

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

if (check_lib( header => 'netcdf.h', lib => 'netcdf',)) {
  $hash{LIBS}[0] .= " -lnetcdf";
}
elsif (qx{which nc-config 2> /dev/null}) {
  warn "Could not find NetCDF libraries using check_lib, falling back to nc-config ...\n";
  my $inc = qx/nc-config --cflags/;
  chomp $inc;
  $hash{INC} .= " $inc";
  my $libs = qx/nc-config --libs/;
  $hash{LIBS}[0] .= $libs;
}
else {
  die "Cannot find NetCDF libraries, tried check_lib and looked for nc-config. Please install NetCDF.";
}

WriteMakefile(%hash);

sub MY::postamble { pdlpp_postamble($package); }
