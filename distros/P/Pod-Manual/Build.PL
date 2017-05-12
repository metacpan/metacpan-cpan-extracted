use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::Manual',
    license             => 'perl',
    dist_author         => 'Yanick Champoux <yanick@cpan.org>',
    dist_version_from   => 'lib/Pod/Manual.pm',
    requires => {
        'XML::LibXML'       => 0,
        'Test::More'        => 0,
        'version'           => 0,
        'Object::InsideOut' => 0,
        'XML::XPathScript'  => '1.51',
        'Pod::XML'          => 0,
        'Pod::Usage'        => 0,  # for podmanual
    },
    script_files        => [ 'script/podmanual' ],
    add_to_cleanup      => [ 'Pod-Manual-*' ],
    create_makefile_pl  => 'passthrough',
    sign                => 1,
);

$builder->create_build_script();
