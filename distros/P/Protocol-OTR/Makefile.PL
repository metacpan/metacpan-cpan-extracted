use strict;
use warnings;

use ExtUtils::MakeMaker;
use Alien::OTR;
use Alien::GCrypt;
use Alien::GPG::Error;

my $libotr = Alien::OTR->new;
my $libgcrypt = Alien::GCrypt->new;
my $libgpgerror = Alien::GPG::Error->new;

WriteMakefile(
    NAME              => 'Protocol::OTR',
    VERSION_FROM      => 'lib/Protocol/OTR.pm',
    PREREQ_PM         => {
      'Alien::OTR' => '4.1.0.0',
      'Params::Validate' => 0,
      'Scalar::Util' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Protocol/OTR.pm', # retrieve abstract from module
       AUTHOR         => 'Alex J. G. Burzyński <ajgb\@cpan.org>') : ()),
    LICENSE           => 'perl',
    LIBS              => [$libotr->libs, $libgcrypt->libs, $libgpgerror->libs], # e.g., '-lm'
    INC               => join(' ', "-I.", $libotr->cflags, $libgcrypt->cflags, $libgpgerror->cflags), # e.g., '-I. -I/usr/include/other'
    CONFIGURE_REQUIRES => {
      'Alien::OTR' => '4.1.0.0',
    },
    TEST_REQUIRES    => {
      'Params::Validate' => 0,
      'IPC::Open3' => 0,
      'IO::Handle' => 0,
      'File::Temp' => 0,
      'File::Spec' => 0,
    },
    BUILD_REQUIRES    => {
      'ExtUtils::CBuilder' => 0,
    },
);

