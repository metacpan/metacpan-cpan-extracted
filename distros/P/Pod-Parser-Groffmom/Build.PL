use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Pod::Parser::Groffmom',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Pod/Parser/Groffmom.pm',
    meta_merge        => {
        resources =>
          { repository => 'http://github.com/Ovid/Pod-Parser-GroffMom', },
    },
    requires => {
        'Moose'            => 0.60,    # hope this one is good enough!
        'MooseX::NonMoose' => 0.07,
        'Perl6::Junction'  => 1.4,
        'Syntax::Highlight::Engine::Kate' => 0.06,
    },
    build_requires => {
        'Test::Most' => 0.21,
        'Test::More' => 0.94,
    },
    add_to_cleanup     => ['Pod-Parser-Groffmom-*'],
    script_files       => ["bin/pod2mom"],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
