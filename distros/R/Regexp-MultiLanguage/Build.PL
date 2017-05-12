use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Regexp::MultiLanguage',
    license             => 'perl',
    dist_author         => 'Robby Walker <robwalker@cpan.org>',
    dist_version_from   => 'lib/Regexp/MultiLanguage.pm',
    build_requires => {
        'Test::More' => 0,
        'Parse::RecDescent' => 0,
    },
    add_to_cleanup      => [ 'Regexp-MultiLanguage-*' ],
);

$builder->create_build_script();
