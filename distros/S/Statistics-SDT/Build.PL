use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Statistics::SDT',
    license           => 'perl',
    dist_author       => 'Roderick Garton <rgarton@cpan.org>',
    dist_version_from => 'lib/Statistics/SDT.pm',
    build_requires    => {
        'Test::More' => '0.98',
    },
    configure_requires => {
        'Module::Build' => '0.4210',
    },
    requires => {
        'List::AllUtils'  => '0.09',
        'Math::Cephes'    => '0.5304',
        'String::Numeric' => '0.9',
        'String::Util' => '1.21',
    },
    add_to_cleanup => ['Statistics-SDT-0.06-*'],
);

$builder->create_build_script();

1;
