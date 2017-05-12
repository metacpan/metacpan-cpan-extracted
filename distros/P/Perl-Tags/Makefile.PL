use strict;
use warnings;
use inc::Module::Install;

name        'Perl-Tags';
all_from    'lib/Perl/Tags.pm';

license     'perl';
author      'osfameron';

requires        'File::Spec';
requires        'File::Temp';
requires        'File::Find::Rule';
requires        'Module::Locate';
requires        'Path::Tiny';
requires        'parent';
test_requires   'Test::More' => 0.42;
test_requires   'Test::Strict';
test_requires   'Test::Exception';
test_requires   'Test::LongString';
test_requires   'Test::Builder' => 0.42;
build_requires  'Data::Dumper';
build_requires  'Capture::Tiny';

# additional modules needed for additional tagging functionality.
recommends      'PPI';

# additional modules required for authoring new versions.
recommends      'App::FatPacked';
# xt_requires:
recommends      'Moose'; # to test syntax of t/Moosy
# recommends 'PPI'; (as above) to test syntax of ::PPI

install_script  'bin/perl-tags';
install_script  'bin/require-perl-tags';
install_script  'bin/require-perl-tags-packed';

auto_install;
WriteAll;
