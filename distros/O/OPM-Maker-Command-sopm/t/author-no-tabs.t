
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/OPM/Maker/Command/sopm.pm',
    'lib/OPM/Maker/Utils/OTRS3.pm',
    'lib/OPM/Maker/Utils/OTRS4.pm',
    't/author-no-bom.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/base/01_simple_json.t',
    't/base/02_intro.t',
    't/base/03_database.t',
    't/base/04_cvs.t',
    't/base/05_foreign_key_create.t',
    't/base/06_type_exception.t',
    't/base/Database.json',
    't/base/ForeignKeyCreate.json',
    't/base/Intro.json',
    't/base/Test.json',
    't/bugs/table_drop/01/Test.txt',
    't/bugs/table_drop/01_packagesetup.t',
    't/bugs/table_drop/Packagesetup.json',
    't/changes/01/Test.txt',
    't/changes/01_changelog.t',
    't/changes/Changelog.json',
    't/changes_file/01/Test.txt',
    't/changes_file/01_changelog.t',
    't/changes_file/Changelog.json',
    't/changes_file/doc/CHANGES',
    't/code_packagesetup/01_code_uninstall.t',
    't/code_packagesetup/02_code_uninstall_pre.t',
    't/code_packagesetup/03_code_uninstall_pre_3.t',
    't/code_packagesetup/04_code_install_package.t',
    't/code_packagesetup/Test.json',
    't/code_packagesetup/TestInstall.json',
    't/code_packagesetup/TestPre.json',
    't/code_packagesetup/TestPre3.json',
    't/column_drop/01_column_drop.t',
    't/column_drop/ColumnDrop.json',
    't/database/phases/01_base.t',
    't/database/phases/02_phase.t',
    't/database/phases/Database.json',
    't/database/phases/Phase.json',
    't/database/uninstall_column_drop/01/Test.txt',
    't/database/uninstall_column_drop/01_packagesetup.t',
    't/database/uninstall_column_drop/Packagesetup.json',
    't/exclude/01/Test.lyx',
    't/exclude/01/Test.txt',
    't/exclude/01_packagesetup.t',
    't/exclude/Packagesetup.json',
    't/foreign_key_drop/01_foreign_key_drop.t',
    't/foreign_key_drop/ForeignKeyDrop.json',
    't/framework/01_framework.t',
    't/framework/Intro.json',
    't/inline_code/01_code_inline.t',
    't/inline_code/Test.json',
    't/inline_code/Test.pm',
    't/kix/01/Test.txt',
    't/kix/01_packagesetup.t',
    't/kix/Packagesetup.json',
    't/otobo/01/Test.txt',
    't/otobo/01_packagesetup.t',
    't/otobo/Packagesetup.json',
    't/otrs3/01/Test.txt',
    't/otrs3/01_packagesetup.t',
    't/otrs3/Packagesetup.json',
    't/otrs4/01/Test.txt',
    't/otrs4/01_packagesetup.t',
    't/otrs4/Packagesetup.json',
    't/otrs5/01/Test.txt',
    't/otrs5/01_packagesetup.t',
    't/otrs5/Packagesetup.json',
    't/simple_code/01_code_uninstall.t',
    't/simple_code/02_code_uninstall_pre.t',
    't/simple_code/03_code_uninstall_pre_3.t',
    't/simple_code/Test.json',
    't/simple_code/TestPre.json',
    't/simple_code/TestPre3.json',
    't/unique_add/01_unique_add.t',
    't/unique_add/UniqueAdd.json',
    't/unique_drop/01_unique_drop.t',
    't/unique_drop/UniqueDrop.json',
    't/warnings/01/Test.txt',
    't/warnings/01_frameworks.t',
    't/warnings/02/Kernel/Output/HTML/Standard/Test.dtl',
    't/warnings/02_filelist.t',
    't/warnings/Test.json',
    't/warnings/TestOneMajor.json'
);

notabs_ok($_) foreach @files;
done_testing;
