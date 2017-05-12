
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/tapper-installer-client.pl',
    'bin/tapper-installer-simnow.pl',
    'lib/Tapper/Installer.pm',
    'lib/Tapper/Installer/Base.pm',
    'lib/Tapper/Installer/Precondition.pm',
    'lib/Tapper/Installer/Precondition/Copyfile.pm',
    'lib/Tapper/Installer/Precondition/Exec.pm',
    'lib/Tapper/Installer/Precondition/Fstab.pm',
    'lib/Tapper/Installer/Precondition/Image.pm',
    'lib/Tapper/Installer/Precondition/Kernelbuild.pm',
    'lib/Tapper/Installer/Precondition/PRC.pm',
    'lib/Tapper/Installer/Precondition/Package.pm',
    'lib/Tapper/Installer/Precondition/Rawimage.pm',
    'lib/Tapper/Installer/Precondition/Repository.pm',
    'lib/Tapper/Installer/Precondition/Simnow.pm',
    't/00-load.t',
    't/author-eol.t',
    't/author-pod-syntax.t',
    't/file_type/tarfile',
    't/misc/dev/disk/by-label/testing',
    't/misc/dev/hda2',
    't/misc/files/Debian/etc/issue',
    't/misc/files/SuSE/etc/SuSE-release',
    't/tapper-installer-base.t',
    't/tapper-installer-precondition-exec.t',
    't/tapper-installer-precondition-image.t',
    't/tapper-installer-precondition-kernelbuild.t',
    't/tapper-installer-precondition-package.t',
    't/tapper-installer-precondition-prc.t',
    't/tapper-installer-precondition-simnow.t',
    't/tapper_systeminstaller_base.t'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
