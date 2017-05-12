use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'String::ZeroButTrue',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/String/ZeroButTrue.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'String-ZeroButTrue-*' ],
);

$builder->create_build_script();
