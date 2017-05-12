use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Net::SMS::ASPSMS',
    license            => 'perl',
    create_makefile_pl => 'passthrough',
    dist_author        => 'Jacques Supciky <supcik@cpan.org>',
    dist_version       => '0.1.6',
    script_files       => qw( script/aspsms ),
    requires           => {
        'perl'            => '5.8.7',
        'Carp'            => 0,
        'Data::Dumper'    => 0,
        'Getopt::Long'    => 0,
        'List::Util'      => 0,
        'LWP::UserAgent'  => 0,
        'overload'        => 0,
        'Pod::Usage'      => 0,
        'Test::More'      => 0,
        'Encode'          => 0,
        'XML::DOM'        => 0,
    },
);

$builder->create_build_script();
