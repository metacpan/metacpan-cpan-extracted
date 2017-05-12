use strict;
use warnings;

my $malloclib = $PDLA::Config{MALLOCDBG}->{libs};
my $mallocinc = $PDLA::Config{MALLOCDBG}->{include};

use ExtUtils::MakeMaker;
WriteMakefile(
 'NAME'	        => 'PDLA::CallExt',
 'VERSION_FROM' => '../../Basic/Core/Version.pm',
 'INC' => "-I../../Basic/Core $mallocinc",
 'LIBS' => [$malloclib],
 (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
