use strict;
use warnings;
use PDLA::Core::Dev;
use PDLA::Config;
use ExtUtils::MakeMaker;
use Config;

my ($include_path, $lib_path, $linkname);
my $ppfile = "GD.pd";
my $package_name = "PDLA::IO::GD";
my $lib_name = "GD";
my $config_flag = 'WITH_GD';
my $config_libs = 'GD_LIBS';
my $config_incs = 'GD_INC';

# here starteth the code for basic Alien::GD
my @find_libs = ( 'libgd.so', 'libgd.a', 'libgd.dll.a', 'bgd.dll' );
my @find_incs = ( 'gd.h' );
my @lib_locations = (
    '/usr/lib64',
    '/usr/local/lib64',
    '/lib64',
    '/usr/lib',
    '/usr/local/lib',
    '/lib',
    split(/ /, $Config{libpth}),
);
my @inc_locations = (
    '/usr/include',
    '/usr/local/include',
    $Config{usrinc},
);

# Look for GD includes/libs
# get locations from perldl.conf, if specified there:
@lib_locations = @{$PDLA::Config{$config_libs}}
    if( defined $PDLA::Config{$config_libs} );
@inc_locations = @{$PDLA::Config{$config_incs}}
    if( defined $PDLA::Config{$config_incs} );

# Look for the libs:
foreach my $libdir ( @lib_locations ) {
    my $found = 0;
    foreach my $find_lib ( @find_libs ) {
        if ( -e "$libdir/$find_lib" ) {
            $lib_path = $libdir;
            $found = 1;
            # The lib name is different on windows, so we need to adjust the LIBS, below:
            $linkname = ( $find_lib =~ /bgd.dll$/ ) ? 'bgd' : 'gd';
        }
        last if $found;
    }
    last if $found;
} # foreach $libdir...

unless( defined( $lib_path ) ) {
    # Cannot find $lib_name library, (@find_libs).
    # Please add the correct library path to Makefile.PL or install $lib_name
}

# Look for the include files:
foreach my $incdir ( @inc_locations ) {
    foreach my $find_inc ( @find_incs ) {
        if ( -e "$incdir/$find_inc" ) {
            $include_path = $incdir;
            last;
        }
    }
}
# here endeth the code for Alien::GD

unless( defined( $include_path ) ) {
  die <<EOF;
Cannot find $lib_name header files, (@find_incs).
Please add the correct library path to Makefile.PL or install $lib_name.
EOF
}

my $package = [$ppfile, $lib_name, $package_name];
my %hash = pdlpp_stdargs($package);
$hash{VERSION_FROM} = $ppfile;
$hash{DEFINE} = $PDLA::Config{GD_DEFINE};
$hash{LIBS} = ["-L$lib_path -l$linkname"];
$hash{INC} = PDLA_INCLUDE() . " -I$include_path";
push @{ $hash{TYPEMAPS} }, 'typemap';
for my $key (qw(BUILD_REQUIRES CONFIGURE_REQUIRES TEST_REQUIRES PREREQ_PM)) {
  $hash{$key}{'PDLA::Core'} = 0;
  $hash{$key}{'PDLA::IO::Misc'} = 0;
}
for my $key (qw(TEST_REQUIRES PREREQ_PM)) {
  $hash{$key}{'List::MoreUtils'} = 0;
}
$hash{META_MERGE} = {
  "meta-spec" => { version => 2 },
  resources => {
    repository => {
      type => 'git',
      url => 'git://github.com/PDLPorters/pdla-io-gd',
      web => 'https://github.com/PDLPorters/pdla-io-gd',
    },
  },
};

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble( $package ); };

WriteMakefile(%hash);
