use strict;
use Module::Build;
Module::Build->new(
    module_name => 'SVN::Churn',
    license     => 'perl',
    requires    => {
        'perl' => 5.006,
        'Class::Accessor' => 0,
        'Chart::Strip' => 0,
        'Date::Parse'  => 0,
        'Getopt::Declare' => 0,
        'List::Util'      => 0,
        'String::ShellQuote' => 0,
        'SVN::Log'    => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    recommends => {
        'SVN::Core'   => 0,
    },
    script_files  => [qw( bin/svn-churn )],
    create_makefile_pl => 'traditional',
   )->create_build_script;
