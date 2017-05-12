use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Return::DataButBool',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/Return/DataButBool.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Contextual::Return' => 0,
    },
    add_to_cleanup      => [ 'Return-DataButBool-*' ],
);

$builder->create_build_script();
