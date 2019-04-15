use strict;
use warnings;
use ExtUtils::MakeMaker;

# do we build PDLA::IO::Browser ?
my @dirs = qw( FastRaw Misc FlexRaw Pnm Storable FITS HDF GD Dicom IDL );
if ($PDLA::Config{WITH_IO_BROWSER} && $PDLA::Config{WITH_IO_BROWSER}) {
   push @dirs, 'Browser';
   print "   Building PDLA::IO::Browser. Turn off WITH_IO_BROWSER if this is incorrect.\n";
} else {
   print "   Not building PDLA::IO::Browser. Turn on WITH_IO_BROWSER if this is incorrect.\n";
}

WriteMakefile(
     'NAME'	=> 'PDLA::IO',
     'VERSION_FROM' => '../lib/PDLA/Rest.pm',
     'PM'       => {
                    'Dumper.pm' => '$(INST_LIB)/PDLA/IO/Dumper.pm',
                    'IO.pod' => '$(INST_LIB)/PDLA/IO.pod',
                   },
     'DIR'      => [ @dirs ],
    (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
