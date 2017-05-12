use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Perl::RunEND',
    license             => 'perl',
    dist_author         => q{David Wright <dvwright@cpan.org>},
    dist_version_from   => 'lib/Perl/RunEND.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More'      => 0,
         'Carp'           => 0,
         'Config'         => 0,
         'File::Temp'     => 0,
         'File::Find'     => 0,
         'File::Spec'     => 0,
         'Pod::Usage'     => 0,
         'Getopt::Long'   => 0,
         'File::Basename' => 0
    },
    requires => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'Perl-RunEND-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
