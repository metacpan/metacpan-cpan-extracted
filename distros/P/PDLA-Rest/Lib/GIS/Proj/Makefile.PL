use strict;
use warnings;
use ExtUtils::MakeMaker;

my $PJ_VERSION;
my $donot;
my $package_name = "PDLA::GIS::Proj";
my $lib_name = "Proj";
my $config_flag = 'WITH_PROJ';
my $config_libs = 'PROJ_LIBS';
my $config_incs = 'PROJ_INC';

my $forcebuild=0;  # Note: forcebuild not used

if (defined $PDLA::Config{$config_flag} && $PDLA::Config{$config_flag}==0) {
  write_dummy_make("Will skip build of $package_name on this system");
  $PDLA::Config{$config_flag}=0;
  return;
}

require Alien::Proj4; # runtime not compile-time so return above will work
my @inc = Alien::Proj4->default_inc;
@inc = @{$PDLA::Config{$config_incs}}
  if $PDLA::Config{$config_incs} and @{$PDLA::Config{$config_incs}};
push @inc, qw(include);
Alien::Proj4->import($PDLA::Config{$config_libs}, \@inc);

if (defined $PDLA::Config{$config_flag} && $PDLA::Config{$config_flag}==1) {
  print "\n   Will forcibly try and build $package_name on this system   \n\n";
  $forcebuild=1;
}

if (!$forcebuild && !Alien::Proj4->installed) {
  write_dummy_make( <<EOF );
\tCannot find $lib_name installation.
\tPlease add the correct library path to perldl.conf or install $lib_name.
Skipping build of $package_name.
EOF
  $PDLA::Config{$config_flag}=0;
  return;
}

my $libflags = Alien::Proj4->libflags;
my $incflags = Alien::Proj4->incflags;

print "Building $package_name. Turn off $config_flag if there are any problems\n";
$PDLA::Config{$config_flag}=1;

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
