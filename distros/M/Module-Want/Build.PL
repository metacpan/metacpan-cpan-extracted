use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Module::Want',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Module/Want.pm',
    requires          => {
        'Test::More'       => 0,
        'Test::Carp'       => 0,
        'File::Spec'       => 0,
        'File::Temp'       => 0,    # testing
        'File::Path::Tiny' => 0,    # testing
    },
    add_to_cleanup => ['Module-Want-*'],
);

$builder->create_build_script();
