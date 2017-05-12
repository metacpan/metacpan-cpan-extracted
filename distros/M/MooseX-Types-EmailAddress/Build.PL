use Module::Build;

my $build = Module::Build->new(
    module_name   => 'MooseX::Types::EmailAddress',
    dist_abstract => 'Valid email address type constraints for Moose',
    dist_author   => 'Stephen Quinney <squinney@inf.ed.ac.uk>',
    dist_version  => '1.1.2',
    license => 'gpl',
    requires => {
        'perl'           => '5.6.1',
        'Moose'          => '1.15',
        'MooseX::Types'  => '0.22',
        'Email::Valid'   => '0',
        'Email::Address' => '0',
    },
    build_requires => {

        'Test::More'        => 0,
    },
    add_to_cleanup => [ 'MANIFEST.bak', 'Changes.bak' ],
    create_makefile_pl => 'traditional',
);
$build->create_build_script;
