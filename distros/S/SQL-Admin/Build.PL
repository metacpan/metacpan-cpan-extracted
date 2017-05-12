
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name => 'SQL::Admin',
    license     => 'perl',
    dist_author => 'Branislav Zahradnik <happy.barney@gmail.com>',
    dist_version_from => 'lib/SQL/Admin.pm',
    requires => {
        'DBI' => 0,
        'Data::Compare' => 0,
        'Getopt::Long' => 0,
        'List::Utils' => 0,
        'Module::Load' => 0,
        'Parse::RecDescent' => 0,
        'Pod::Usage' => 0,
        'SQL::Abstract' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Attribute::Handlers' => 0,
    },
    add_to_cleanup => [ 'SQL-Admin-*' ],
    create_readme => 1,
    meta_merge => {
        resources => {
            repository => 'https://github.com/happy-barney/perl-SQL-Admin',
            bugtracker => 'https://github.com/happy-barney/perl-SQL-Admin/issues',
        },
    },
);
$builder->create_build_script();
