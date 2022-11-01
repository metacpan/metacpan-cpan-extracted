use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Pg::SQL::PrettyPrinter',
    dist_abstract      => 'Pretty printer for SQL queries',
    license            => 'bsd',
    dist_author        => 'hubert depesz lubaczewski <depesz@depesz.com>',
    dist_version_from  => 'lib/Pg/SQL/PrettyPrinter.pm',
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'autodie'         => 0,
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },
    add_to_cleanup => [ 'Pg-SQL-PrettyPrinter-*' ],
    requires       => {
        'Clone'           => 0,
        'HTTP::Tiny'      => 0,
        'JSON::MaybeXS'   => 0,
        'Module::Runtime' => 0,
    },
    meta_merge => {
        'meta-spec' => {
            version => 2,
        },
        resources => {
            repository => {
                url  => 'https://gitlab.com/depesz/pg-sql-prettyprinter.git',
                web  => 'https://gitlab.com/depesz/pg-sql-prettyprinter',
                type => 'git',
            },
            bugtracker => {
                web => 'https://gitlab.com/depesz/pg-sql-prettyprinter/-/issues',
            },
            homepage => 'https://gitlab.com/depesz/pg-sql-prettyprinter'
        },
    },
);

$builder->create_build_script();
