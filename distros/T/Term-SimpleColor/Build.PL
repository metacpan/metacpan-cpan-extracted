use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Term::SimpleColor',
    license             => 'artistic',
    dist_author         => 'Takashi Uesugi <tksuesg@gmail.com>',
    dist_version_from   => 'lib/Term/SimpleColor.pm',
    dist_abstract       => 'A very simple color screen output',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Term-SimpleColor-*' ],
);

$builder->create_build_script();
