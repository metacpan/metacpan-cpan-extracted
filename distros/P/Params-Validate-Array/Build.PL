use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Params::Validate::Array',
    license             => 'perl',
    dist_author         => 'Sam Brain <samb@stanford.edu>',
    dist_version_from   => 'lib/Params/Validate/Array.pm',
    requires => {
        'Params::Validate' => 1.07,
        'Test::More'       => 0,
        'Carp'             => 0,
        'version'          => 0,
    },

    configure_requires => {
      'Module::Build' => 0.38
    },

    add_to_cleanup      => [ 'Params-Validate-Array-*' ],
);

$builder->create_build_script();
