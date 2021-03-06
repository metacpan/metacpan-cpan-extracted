use inc::Module::Install;
name 'Mobile-Data-SID';
perl_version '5.008';
license 'perl';
all_from 'lib/Mobile/Data/SID.pm';

recommends $_ for (qw/
    LWP::Simple
    Getopt::Long
/);

requires $_ for (qw/
    File::ShareDir
    CDB_File
    Exporter
/);

install_share 'share';
build_requires 'Test::Base';
build_requires 'ExtUtils::MakeMaker' => 6.42;
use_test_base;
auto_include;
WriteAll;

