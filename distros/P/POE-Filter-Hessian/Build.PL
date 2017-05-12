use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'POE::Filter::Hessian',
    license     => 'perl',

    dist_author => 'William Travis Holton <cromulent2000_eisley@yahoo.de>',
    dist_version_from    => 'lib/POE/Filter/Hessian.pm',
    recursive_test_files => 1,
    requires             => {
        'Test::More'         => 0,
        'Test::Class'        => 0,
        'Test::Deep'         => 0,
        'Perl::Critic'       => 0,
        'Test::Perl::Critic' => 0,
        'version'            => 0,
        'Contextual::Return' => 0,
        'Moose'              => 0,
        'MooseX::Clone'      => 0,
        'Exception::Class'   => 0,
        'Smart::Comments'    => 0,
        'YAML'               => 0,
        'Hessian::Translator'    => 1.00

    },
    add_to_cleanup => ['POE-Filter-*'],
);

$builder->create_build_script();
