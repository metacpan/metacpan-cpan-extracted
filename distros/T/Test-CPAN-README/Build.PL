use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Test::CPAN::README',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Test/CPAN/README.pm',
    requires          => {
        'Test::More'    => 0,
        'Test::Builder' => 0,
        'Module::Want'  => 0,
        'YAML::Syck'    => 0,
        'JSON::Syck'    => 0,
    },
    add_to_cleanup => ['Test-CPAN-README-*'],
);

$builder->create_build_script();
