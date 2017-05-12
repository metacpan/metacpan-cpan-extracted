use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Perl6::Export::Attrs',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@cpan.org>',
    dist_version_from   => 'lib/Perl6/Export/Attrs.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Attribute::Handlers' => 0,
    },
    add_to_cleanup      => [ 'Perl6-Export-Attrs-*' ],
);

$builder->create_build_script();
