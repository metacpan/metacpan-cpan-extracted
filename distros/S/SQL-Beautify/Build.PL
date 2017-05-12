use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SQL::Beautify',
    license             => 'artistic_2',
    dist_author         => 'Jonas Kramer <jkramer@cpan.org>',
    dist_version_from   => 'lib/SQL/Beautify.pm',
    requires => {
        'Carp'           => 0,
        'Getopt::Long'   => 0,
        'SQL::Tokenizer' => 0.19,
    },
    build_requires => {
        'Test::More'     => 0,
    },
    add_to_cleanup      => [ 'SQL-Beautify-*' ],
    create_makefile_pl => 'traditional',
    script_files => ['script/sqlbeautify'],
    meta_merge => {
        resources => {
            repository => 'https://github.com/jkramer/sql-beautify'
        }
    },
);

$builder->create_build_script();
