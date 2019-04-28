use strict;
use warnings;
use File::Spec;
use PDLA::Core::Dev;

my $malloclib = $PDLA::Config{MALLOCDBG}->{libs};
my $mallocinc = $PDLA::Config{MALLOCDBG}->{include};

my $core = $INC{'PDLA/Core/Dev.pm'};
my ($volume,$directories,$file) = File::Spec->splitpath($core);
my @dirs = File::Spec->splitdir($directories);
$file = pop @dirs; # so get the dir to give to catpath
$directories = File::Spec->catdir( @dirs );
my $corepath = File::Spec->catpath($volume, $directories, $file);

my @cleanup = (qw(
    t/callext$(OBJ_EXT) t/callext.$(DLEXT)
));

use ExtUtils::MakeMaker;
WriteMakefile(
 'NAME'	        => 'PDLA::CallExt',
 'VERSION_FROM' => '../../lib/PDLA/Rest.pm',
 'INC' => qq{-I"$corepath" $mallocinc},
 'LIBS' => [$malloclib],
 (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
 clean => { FILES => join ' ', @cleanup },
);
