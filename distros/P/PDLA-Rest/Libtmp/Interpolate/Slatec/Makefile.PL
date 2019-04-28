use strict;
use warnings;
use ExtUtils::MakeMaker;

# do we build PDLA::Interpolate::Slatec ?

my $msg = "\n Will skip build of PDLA::Interpolate::Slatec\n";
my $build=0;
 
if ($^O =~ /win32/i) {
    $msg = "\n Win32 systems not yet supported: no build of PDLA::Interpolate::Slatec\n";
} elsif (defined $PDLA::Config{WITH_SLATEC} and $PDLA::Config{WITH_SLATEC} != 0 ) {
    $build=1;
} 

if ($build==0) {
    write_dummy_make( $msg );
    return;
} else {
    print "\n Building PDLA::Interpolate::Slatec.\n\n";
}                                                                            

WriteMakefile(
	      NAME => "PDLA::Interpolate::Slatec",
	      VERSION_FROM => "../../../lib/PDLA/Rest.pm",
);
