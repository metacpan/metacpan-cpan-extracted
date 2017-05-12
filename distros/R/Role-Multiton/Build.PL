use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Role::Multiton',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Role/Multiton.pm',
    requires          => {
        'Test::More'      => 0,    # testing
        'Moo'             => 0,    # testing
        'Test::Exception' => 0,    # testing
        'Role::Tiny'      => 0,
    },
    add_to_cleanup => ['Role-Multiton-*'],
);

$builder->create_build_script();
