use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::FisherPitman',
    license             => 'perl',
    dist_author         => 'Roderick Garton <rgarton@cpan.org>',
    dist_version_from   => 'lib/Statistics/FisherPitman.pm',
    build_requires => {
        'Test::More' => 0,
        'List::Util' => 1.18,
        'Statistics::Descriptive' => 2.6,
    },
    add_to_cleanup      => [ 'Statistics-FisherPitman-0.034-*' ],
);

$builder->create_build_script();
