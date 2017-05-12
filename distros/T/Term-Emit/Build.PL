use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Term::Emit',
    license             => 'perl',
    dist_author         => 'Steve Roscio <roscio@cpan.org>',
    dist_version_from   => 'lib/Term/Emit.pm',
    requires => {
        'Scope::Upper'  => '0.06',
        'Test::More'    => 0,
    },
    add_to_cleanup      => [ 'Term-Emit-*' ],
);

$builder->create_build_script();
