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
    requires       => { 'Clone' => 0, 'YAML::XS' => '0.83', 'JSON::MaybeXS' => 0, 'XML::Simple' => 0, 'Digest::SHA' => 0, 'HOP::Lexer' => 0, 'perl' => '5.018', 'List::Util' => '1.44', },
    meta_merge     => {
        'meta-spec' => {
            version => 2,
        },
        resources => {
            repository => {
                url  => 'https://gitlab.com/depesz/Pg--Explain.git',
                web  => 'https://gitlab.com/depesz/Pg--Explain',
                type => 'git',
            },
            bugtracker => {
                web => 'https://gitlab.com/depesz/Pg--Explain/-/issues',
            },
            homepage => 'https://gitlab.com/depesz/Pg--Explain'
        },
    },
);

$builder->create_build_script();
