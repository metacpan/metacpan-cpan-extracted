use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'String::BOM',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/String/BOM.pm',
    requires => {
        'File::Slurp' => 0,
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'String-BOM-*' ],
);

$builder->create_build_script();
