use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Prolog::Utility::FromPerl',
    license             => 'artistic2',
    dist_author         => 'Tyson Maly <tvmaly@cpan.org>',
    dist_version_from   => 'lib/Prolog/Utility/FromPerl.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Regexp::Common'    => 0
    },
    add_to_cleanup      => [ 'Prolog-Utility-FromPerl-*' ],
);

$builder->create_build_script();
