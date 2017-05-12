# Makefile.PL for a package defined by PP code.

use PDL::Core::Dev;            # Pick up development utilities
use ExtUtils::MakeMaker;
use Config;
use Data::Dumper;
use File::Spec;

# 
## Search for netcdf library and include file
#

foreach my $libdir (
		    $ENV{NETCDF_LIBDIR},
		    '/usr/local/netcdf/lib',
		    '/usr/local/lib',
		    '/opt/local/lib',
		    '/usr/lib',
		    '/usr/lib64',
		    '/opt/lib',
                    '/usr/local/lib64', # Added at request of Hernan De Angelis, 9/16/2013
		                  # Add new library paths here!!
		    ) {

  if (-e "$libdir/libnetcdf.so") {
    $netcdf_lib_path = $libdir;
    print "Found libnetcdf.so at $libdir/libnetcdf.so\n";
    last;
  }

  if (-e "$libdir/libnetcdf.a") {
    $netcdf_lib_path = $libdir;
    print "Found libnetcdf.a at $libdir/libnetcdf.a\n";
    last;
  }

}

die "Cannot find netcdf library, libnetcdf.so or libnetcdf.a.  
Please set the environment variable NETCDF_LIBDIR to the correct library path or install NetCDF" 
  unless defined ($netcdf_lib_path);

foreach my $incdir (
		    $ENV{NETCDF_INCDIR},
		    '/usr/local/netcdf/include',
		    '/usr/local/include',
		    '/opt/local/include',
		    '/usr/include',
		    '/opt/include',
		                  # Add new header paths here!!
		    ) {

  if (-e "$incdir/netcdf.h") {
    $netcdf_include_path = $incdir;
    print "Found netcdf.h at $incdir/netcdf.h\n";
    last;
  }
}

die "Cannot find netcdf header file, netcdf.h.
Please set the environment variable NETCDF_INCDIR to the correct include path or install NetCDF" 
  unless defined ($netcdf_include_path);

# Check if compiled under gcc/Linux.  In which case, define bool for the compiler
$define_bool = '';
if ($Config{'osname'} =~ linux) {
  $define_bool = '-Dbool=int';
  print "Defining bool=int (linux seems to need this)\n";
}

my $devnull = File::Spec->devnull(); # Portable null device.
my %ncversion = (); # Information on which netcdf functions/features available.
$ncversion{'nc_inq_var_deflate'} = test_func_exists('nc_inq_var_deflate', 'HDF library installed',
                                                    'nc_inq_var_deflate(0, 0, NULL, NULL, NULL);');

# Write these options to a file--used by netcdf.pd during the 'make' step
open my $fh, '>', 'OPTIONS!' or die "Cannot write to OPTIONS! file";
print  {$fh} Dumper(\%ncversion);
close   $fh;

$package = ["netcdf.pd",NetCDF,PDL::NetCDF];
WriteMakefile(
	      'NAME'  	     => 'PDL::NetCDF',
	      'AUTHOR'       => 'Douglas Hunt (dhunt@ucar.edu)',
	      'PREREQ_PM'    => { PDL => 0 },
	      'CCFLAGS'      => "$define_bool -g",  
	      'VERSION_FROM' => 'netcdf.pd',
	      'META_MERGE'   =>  {provides => {PDL::NetCDF => {file => 'netcdf.pd', version => 4.19}}},
	      'TYPEMAPS'     => [&PDL_TYPEMAP()], 
	      'OBJECT'       => 'NetCDF.o ',
	      'PM'           => { 'NetCDF.pm' => '$(INST_LIBDIR)/NetCDF.pm'},
	      'INC'          => &PDL_INCLUDE()." -I$netcdf_include_path", 
	      'LIBS'         => ["-L$netcdf_lib_path -lnetcdf $ENV{NETCDF_EXTRALIBS}"],  
	      'clean'        => {'FILES'  => 
				   'NetCDF.pm NetCDF.xs NetCDF.o NetCDF.c'},
	      'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz' },	
	      );

sub MY::postamble { pdlpp_postamble($package); }

sub test_func_exists {

    my ( $func, $comment, $eval, $option ) = @_;

    $option = $func unless defined $option;

    # Test if PLplot has plsmem, for in memory plotting
    eval { compileAndRun ("-I$netcdf_include_path -L$netcdf_lib_path -lnetcdf $ENV{NETCDF_EXTRALIBS}", 0, <<"EOC");
#include <netcdf.h>
main () {  $eval }
EOC
       };

    my $have_func;
    if ($@)
    {
	print "\t$func function not found, no $comment available\n";
	$have_func = 0;
    }
    else
    {
	print "\t$func function found, $comment available!\n";
	$have_func = 1;
    }

    return $have_func;
}

sub compileAndRun {
  my $flags = shift;
  my $run   = shift;
  my $code  = shift;

  open (OUT, ">temp.c");
  print OUT $code;
  close OUT;
  unlink './temp'; # since we work out whether the compile succeeds by presence of this
  unlink './temp.exe'; # since we work out whether the compile succeeds by presence of this

  my $cc = $Config{cc};
  my $ccflags = $Config{ccflags};
  print "Trying: $cc $ccflags $flags temp.c -o temp\n";

  # The duplication of $flags seems to be necessary, as some systems
  # need $flags before temp.c and some after.  D. Hunt 2/9/2011
  system "$cc $ccflags $flags temp.c $flags -o temp > $devnull 2>&1";
  unlink('./temp.c');
  die "Cannot compile test program: $code" unless (-e 'temp' or -e 'temp.exe');
  return unless ($run);

  my $res = `./temp`;
  unlink ('./temp');
  unlink ('./temp.exe');
  return $res;
}





