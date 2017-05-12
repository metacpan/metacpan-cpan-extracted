# Makefile.PL for a package defined by PP code.

# Check for a PDL installation
BEGIN
 {

    eval{ require PDL::Core::Dev };
    if( $@ ){
            print "\n#### Error requiring 'PDL::Core::Dev': Perhaps you don't have PDL installed ###\n";
            print "####  This module requires a PDL installation                           ###\n";
            
	    require ExtUtils::MakeMaker;
	    import  ExtUtils::MakeMaker;

            # Write out a simple makefile with PREREQ_PM, so CPAN will at least detect our
            #   prerequesites.
            WriteMakefile( 
                'VERSION_FROM'  => 'hdf5.pd',
                'NAME'     => 'PDL::IO::HDF5',
                'DISTNAME' => "PDL-IO-HDF5",
                'CONFIGURE_REQUIRES' => { PDL => '2.004' },
                'BUILD_REQUIRES'     => { PDL => '2.004' },
                'PREREQ_PM'          => { PDL => '2.004' },
		'LICENSE'  => 'perl',
                );
            exit();
    }
    
}  


use PDL::Core::Dev;            # Pick up development utilities
use ExtUtils::MakeMaker;
use Config;

# 
## Search for hdf5 library and include file
#
$ENV{'HOME'} = '' unless defined( $ENV{'HOME'} ) ;
$ENV{'HDF5_PATH'} = '' unless defined ( $ENV{'HDF5_PATH'} );

@libdirs =  (
    $ENV{'HDF5_PATH'}."/lib",
    $ENV{'HDF5_PATH'}."/lib64",
    split(/ /, $Config{libpth}),  # TODO: This will break for paths with spaces
    '/usr/local/hdf5/lib',
    '/usr/local/lib',
    '/opt/local/lib',
    '/usr/lib',
    '/opt/lib',
    '/usr/lib64'
    );
push(@libdirs,split(":",$ENV{'LD_LIBRARY_PATH'}));
foreach my $libdir ( @libdirs ) {
    
  if (-e "$libdir/libhdf5.so") {
    $hdf5_lib_path = $libdir;
    print "Found libhdf5.so at $libdir/libhdf5.so\n";
    last;
  }

  if (-e "$libdir/libhdf5.dll.a") {
    $hdf5_lib_path = $libdir;
    print "Found libhdf5.dll.a at $libdir/libhdf5.dll.a\n";
    last;
  }

  if (-e "$libdir/libhdf5.a") {
    $hdf5_lib_path = $libdir;
    print "Found libhdf5.a at $libdir/libhdf5.a\n";
    last;
  }

}

# We don't do a die here, because we would get bogus emails from CPAN testers
unless(defined ($hdf5_lib_path) ){
	print "####### Cannot find hdf5 library, libhdf5.so or libhdf5.a.  
#######   Please add the correct library path to Makefile.PL or install HDF\n";
	exit();
} 

@incdirs =  (
    $ENV{'HDF5_PATH'}."/include",
    $Config{usrinc},
    '/usr/local/hdf5/include',
    '/usr/local/include',
    '/opt/local/include',
    '/usr/include',
    '/opt/include'
    );
push(@incdirs,map { local $_ = $_; $_ =~ s/\/lib([^\/]+)$/\/include/; $_ } split(":",$ENV{'LD_LIBRARY_PATH'}));
foreach my $incdir ( @incdirs ) {
    if (-e "$incdir/hdf5.h") {
    $hdf5_include_path = $incdir;
    print "Found hdf5.h at $incdir/hdf5.h\n";
    last;
  }
}

# We don't do a die here, because we would get bogus emails from CPAN testers
unless ( defined ($hdf5_include_path) ){
	print "####### Cannot find hdf5 header file, hdf5.h.
#######   Please add the correct library path to Makefile.PL or install HDF5\n";
	exit();
} 

# Flags to include jpeg and/or zlib during compilation
$jpegLib = 0;
$zLib = 0;
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
$define_bool = '';
if ($Config{'osname'} =~ /linux/) {
  $define_bool = '-Dbool=int';
  print "Defining bool=int (linux seems to need this)\n";
}

#If in win32, add the required defined for the HDF5 libs to work:
$define_win32HDF = '';
if ($Config{'osname'} =~ /win32/i) {
  $define_win32HDF = '-D _HDF5USEDLL_ -D HASATTRIBUTE ';
  print "Defining _HDF5USEDLL_ for win32\n";
}
            
$LIBS = "-L$hdf5_lib_path -lhdf5 ";
$LIBS .= " -lz" if($zLib);
$LIBS .= " -ljpeg" if($jpegLib);
$LIBS .= " -lm";

$package = ["hdf5.pd",HDF5,PDL::IO::HDF5];
$meta_merge = {
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
            'Test::More' => '0',
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
         web    => 'http://rt.cpan.org/Public/Dist/Display.html?Name=PDL-IO-HDF5',
      },
      repository  => {
         url  => 'git://git.code.sf.net/p/pdl/pdl-io-hdf5',
         web  => 'http://sourceforge.net/p/pdl/pdl-io-hdf5/ci/master/tree/',
         type => 'git',
      },
   },
   'dynamic_config' => 1,
   'meta-spec' => {
      'version' => '2',
      'url'     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
   },
   'generated_by' => 'Chris Marshall',
   'provides' => {
      'PDL::IO::HDF5' => {
         'file' => 'hdf5.pd',
         'version' => '0.73',
      },
   },
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
	      'VERSION_FROM' => 'hdf5.pd',   # Need to fix duplicate info in provides META key
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
				   'HDF5.pm HDF5.xs HDF5.o HDF5.c'},
	      'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz', PREOP => $preop },	
	      );

sub MY::postamble { pdlpp_postamble($package); }	





