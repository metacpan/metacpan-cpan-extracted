use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Regexp::Grammars',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@CPAN.org>',
    dist_version_from   => 'lib/Regexp/Grammars.pm',
    requires => {
        'Test::More'   => 0,
        'version'      => 0,
        'perl'         => '5.10.0',
    ($] >= 5.018 ? (
        'B::Hooks::Parser' => 0.16,
    ) : ())
    },
    add_to_cleanup      => [ 'Regexp-Grammars-*' ],
);

$builder->create_build_script();
