use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    'module_name' => "Net::SeedServe",
    configure_requires => { 'Module::Build' => '0.39', },
    'requires' =>
    {
        'perl' => '5.008',
        'IO::All' => 0.33,
        'Test::More' => 0,
        'Time::HiRes' => 1.59,
    },
    'license' => 'mit',
    create_makefile_pl => 'traditional',
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/gimp-test-suite",
        },
    },
);
$builder->create_build_script;

