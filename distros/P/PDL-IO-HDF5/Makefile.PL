use strict;
use warnings;
use PDL::Core::Dev;            # Pick up development utilities
use ExtUtils::MakeMaker;
use Config;

## Search for hdf5 library and include file
$ENV{HDF5_PATH} ||= '';

sub get_lib_paths {
  permutate(grep $_, (
    $ENV{HDF5_PATH}."/lib",
    $ENV{HDF5_PATH}."/lib64",
    $ENV{HDF5_LIBDIR},
    split(/ /, $Config{libpth}),  # TODO: This will break for paths with spaces
    '/usr/local/hdf5/lib',
    '/usr/local/lib',
    '/opt/local/lib',
    '/usr/lib',
    '/opt/lib',
    '/usr/lib64',
    split(":",$ENV{LD_LIBRARY_PATH}||''),
  ));
}
sub permutate {
  (
    @_,
    (map "$_/serial", @_),
    (map "$_/hdf5/serial", @_),
  );
}
my @lib_base = qw(hdf5 hdf5_serial);

my ($hdf5_lib_path, $hdf5_lib_base);
DIR: foreach my $libdir ( get_lib_paths() ) {
  for my $extension (".$Config{dlext}", $Config{_a}, ".dll.a") {
    for my $base (@lib_base) {
      my $shortfile = "lib$base$extension";
      my $file = "$libdir/$shortfile";
      next if !-e $file;
      $hdf5_lib_path = $libdir;
      $hdf5_lib_base = $base;
      print "Found $shortfile at $file\n";
      last DIR;
    }
  }
}

# We don't do a die here, because we would get bogus emails from CPAN testers
unless(defined ($hdf5_lib_path) ){
  print "####### Cannot find hdf5 library, libhdf5.so or libhdf5.a.
#######   Please add the correct library path to Makefile.PL or install HDF\n";
  exit();
}

my $hdf5_include_path;
foreach my $incdir (
  permutate($Config{usrinc}),
  (map { my $s = $_; $s =~ s/\/lib[^\/]*/\/include/; $s } get_lib_paths()),
) {
  my $shortfile = "hdf5.h";
  my $file = "$incdir/$shortfile";
  if (-e $file) {
    $hdf5_include_path = $incdir;
    print "Found $shortfile at $file\n";
    last;
  }
}

# We don't do a die here, because we would get bogus emails from CPAN testers
unless ( defined ($hdf5_include_path) ){
  print "####### Cannot find hdf5 header file, hdf5.h.
#######   Please add the correct include path to Makefile.PL or install HDF5\n";
  exit();
}

# Flags to include jpeg and/or zlib during compilation
my $jpegLib = 0;
my $zLib = 0;
if( -e "$hdf5_include_path/H5config.h"){
	open( H5CONFIG, "$hdf5_include_path/H5config.h") or
           die("Can't Open Include File '$hdf5_include_path/H5config.h'\n");
	while(defined( $_ = <H5CONFIG>)){
		$jpegLib = 1 if( /^\s*\#define\s+HAVE_LIBJPEG\s+1/ );
		$zLib = 1 if( /^\s*\#define\s+HAVE_LIBZ\s+1/ );
	}
}

# The following code was originally in the PDL::netCDF Makefile.PL
#  (Not sure if it is really needed here)
# Check if compiled under gcc/Linux.  In which case, define bool for the compiler
my $define_bool = '';
if ($Config{'osname'} =~ /linux/) {
  $define_bool = '-Dbool=int';
  print "Defining bool=int (linux seems to need this)\n";
}

#If in win32, add the required defined for the HDF5 libs to work:
my $define_win32HDF = '';
if ($Config{'osname'} =~ /win32/i) {
  $define_win32HDF = '-D _HDF5USEDLL_ -D HASATTRIBUTE ';
  print "Defining _HDF5USEDLL_ for win32\n";
}

my $LIBS = "-L$hdf5_lib_path -l$hdf5_lib_base ";
$LIBS .= " -lz" if($zLib);
$LIBS .= " -ljpeg" if($jpegLib);
$LIBS .= " -lm";

my $package = ["hdf5.pd",'HDF5','PDL::IO::HDF5'];
my $meta_merge = {
   'name' => 'PDL-IO-HDF5',
   'abstract' => 'PDL Interface to the HDF5 Data Format',
   'release_status' => 'stable',   # 'testing',
   'author'   => [ 'Chris Marshall <chm@cpan.org>', ],
   'license'  => [ 'perl_5' ],
   'version' => '0.73',
   'meta_spec' => {
      'version' => '2',
      'url'     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
   },
   'prereqs' => {
      'runtime' => {
         'requires' => {
            'PDL' => '2.004',
         },
      },
      'build' => {
         'requires' => {
            'ExtUtils::MakeMaker' => '0',
            'PDL' => '2.007',
         },
      },
      test => {
         requires => {
            'Test::More' => '0.88', # done_testing
         },
      },
      'configure' => {
         'requires' => {
            'ExtUtils::MakeMaker' => '0',
            'PDL' => '2.004',
         },
      },
   },
   resources => {
      license     => [ 'http://cpansearch.perl.org/src/CHM/PDL-IO-HDF5-0.73/COPYRIGHT' ],
      homepage    => 'http://pdl.perl.org/',
      bugtracker  => {
         web    => 'https://github.com/PDLPorters/pdl-io-hdf5/issues',
      },
      repository  => {
         url  => 'git@github.com:PDLPorters/pdl-io-hdf5.git',
         web  => 'https://github.com/PDLPorters/pdl-io-hdf5',
         type => 'git',
      },
   },
   'dynamic_config' => 1,
   'meta-spec' => {
      'version' => '2',
      'url'     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
   },
   'generated_by' => 'Chris Marshall',
};
# create GENERATED subdir with *.pm files during 'make dist' (to make metacpan.org happy)
my $preop = '$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -MPDL::Core::Dev -e pdlpp_mkgen $(DISTVNAME)';

WriteMakefile(
  'NAME'  	     => 'PDL::IO::HDF5',
  'CCFLAGS'      => "$Config{ccflags} $define_bool $define_win32HDF -DH5_USE_16_API -g",
  'CONFIGURE_REQUIRES' => { PDL => '2.004' },
  'BUILD_REQUIRES'     => { PDL => '2.004' },
   # 'TEST_REQUIRES'      => { PDL => '2.004' },
  'PREREQ_PM'          => { PDL => '2.004' },
  'LICENSE'      => 'perl',
  'VERSION_FROM' => 'hdf5.pd',
  'META_MERGE'   => $meta_merge,
  'TYPEMAPS'     => [&PDL_TYPEMAP()],
  'OBJECT'       => 'HDF5.o ',
  'PM'           => { 'HDF5.pm' => '$(INST_LIBDIR)/HDF5.pm',
                      'HDF5/Group.pm' => '$(INST_LIBDIR)/HDF5/Group.pm',
                      'HDF5/Dataset.pm' => '$(INST_LIBDIR)/HDF5/Dataset.pm',
                      'HDF5/tkview.pm' => '$(INST_LIBDIR)/HDF5/tkview.pm',
                    },
  'INC'          => &PDL_INCLUDE()." -I$hdf5_include_path",
  'LIBS'         => [$LIBS],
  'clean'        => {'FILES'  =>
                       'HDF5.pm HDF5.xs HDF5.o HDF5.c newFile.hdf5'},
  'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz', PREOP => $preop },
);

sub MY::postamble { pdlpp_postamble($package); }	
