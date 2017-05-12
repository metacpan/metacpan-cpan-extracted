use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Regexp::MatchContext',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@cpan.org>',
    dist_version_from   => 'lib/Regexp/MatchContext.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Tie::StdScalar' => 0,
    },
    add_to_cleanup      => [ 'Regexp-MatchContext-*' ],
);

$builder->create_build_script();
