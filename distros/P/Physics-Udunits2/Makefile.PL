use 5.006;
use ExtUtils::MakeMaker;
use Config;
use strict;

# 
## Search for udunits2 library and include file
#
my ($udunits_lib_path, $udunits_inc_path);
foreach my $libdir (
                    $ENV{UDUNITS2_LIBDIR},
                    '/usr/local/udunits2/lib',
                    '/usr/local/lib',
                    '/opt/local/lib',
                    '/usr/lib',
                    '/opt/lib',
                                  # Add new library paths here!!
                    ) {
    my $dynlib = "$libdir/libudunits2." . $Config{dlext};
    if (-e $dynlib) {
        $udunits_lib_path = $libdir;
        print "Found libudunits2 at $dynlib\n";
        last;
    }
    my $staticlib = "$libdir/libudunits2.a";
    if (-e $staticlib) {
        $udunits_lib_path = $libdir;
        print "Found static libudunits2 at $staticlib\n";
        last;
    }
}
if (!defined $udunits_lib_path) {
	die <<EODIE;
Cannot find libudunits2. Please install udunits2 and set the
environment variable UDUNITS2_LIBDIR to the installed directory, i.e. /my/home/udunits2/lib
EODIE
}

foreach my $incdir (
                    $ENV{UDUNITS2_INCDIR},
                    '/usr/local/udunits2/include',
                    '/usr/local/include',
                    '/opt/local/include',
                    '/usr/include',
                    '/opt/include',
                                  # Add new header paths here!!
                    ) {
    if (-e "$incdir/udunits2.h") {
        $udunits_inc_path = $incdir;
        print "Found udunits2.h at $incdir/netcdf.h\n";
        last;
    }
}
if (!defined $udunits_inc_path) {
    die <<EODIE;
Cannot find udunits2.h Please install udunits2 and set the
environment variable UDUNITS2_INCDIR to the installed directory, i.e. /my/home/udunits2/include
EODIE
}



# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Physics::Udunits2',
    VERSION_FROM      => 'lib/Physics/Udunits2.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Physics/Udunits2.pm', # retrieve abstract from module
       AUTHOR         => 'Heiko Klein <heiko.klein@met.no>') : ()),
    LIBS              => ["-L$udunits_lib_path".' -ludunits2 -lm'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. -I$udunits_inc_path", 
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
