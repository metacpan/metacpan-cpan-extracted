use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Perl::Critic::PetPeeves::JTRAMMELL',
    license             => 'perl',
    dist_author         => 'John Trammell <johntrammell@gmail.com>',
    dist_version_from   => 'lib/Perl/Critic/PetPeeves/JTRAMMELL.pm',
    requires => {
        'Perl::Critic::Policy' => 0,
        'Perl::Critic::Utils'  => 0,
    },
    build_requires => {
        'Test::More'           => 0,
        'Perl::Critic::Config' => 0,
    },
    add_to_cleanup      => [
        'Perl-Critic-PetPeeves-JTRAMMELL-*',
        '*.bak'
    ],
);

$builder->create_build_script;
