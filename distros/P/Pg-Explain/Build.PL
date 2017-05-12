use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Pg::Explain',
    license            => 'perl',
    dist_author        => 'hubert depesz lubaczewski <depesz@depesz.com>',
    dist_version_from  => 'lib/Pg/Explain.pm',
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'autodie'         => 0,
        'Test::More'      => 0,
        'Test::Deep'      => 0,
        'Test::Exception' => 0,
    },
    add_to_cleanup => [ 'Pg-Explain-*' ],
    requires       => { 'Clone' => 0, 'YAML' => 0, 'JSON' => 0, 'XML::Simple' => 0, 'Digest::SHA1' => 0, 'HOP::Lexer' => 0, 'perl' => '5.010' },
);

$builder->create_build_script();
