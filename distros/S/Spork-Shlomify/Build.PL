use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Spork::Shlomify',
    license             => 'mit',
    dist_author         => 'Shlomi Fish',
    dist_version_from   => 'lib/Spork/Shlomify.pm',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires => {
        'perl' => '5.008',
        'Spoon' => 0,
        'Spork' => 0,
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Spork-Shlomify-*' ],
    script_files => [ "bin/shspork" ],
    create_makefile_pl => "traditional",
    meta_merge =>
    {
        resources =>
        {
            repository => 'http://github.com/shlomif/perl-Spork-Shlomify',
        },
    },
);

$builder->create_build_script();
