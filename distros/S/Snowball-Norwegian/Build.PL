use strict;
use warnings;
use Module::Build;

sub YES { 1 };
sub NO  { 0 };

my $builder = Module::Build->new(
    module_name          => 'Lingua::Stem::Snowball::No',
    license              => 'perl',
    dist_name            => 'Snowball-Norwegian',
    dist_author          => 'Ask Solem <ASKSH@cpan.org>',
    dist_version_from    => 'lib/Lingua/Stem/Snowball/No.pm',
    all_from             => 'lib/Lingua/Stem/Snowball/No.pm',
    dist_abstract        => 'Porters stemming algorithm for norwegian.',
    dynamic_config       => NO,
    sign                 => NO, # asksh: have to find out why my signature fails.
    recursive_test_files => YES,
    build_requires       => {
        'Test::More'            => 0.42,
    },
    pod_files            => {
    },
    add_to_cleanup       => [ qw(
        a.out
        test.pl
        test.c
        test.cpp
        test.m
        *.swp
        .gdb_history
        install.cache
        t/cache
    ) ],
);

$builder->create_build_script( );

