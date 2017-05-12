use Module::Build;
my $build = Module::Build->new (
    dist_name           => 'SSH-RPC',
    dist_version_from   => 'lib/SSH/RPC/Client.pm',
    license             => 'perl',
    create_readme       => 1,
    sign                => 0,
    create_makefile_pl  => 'traditional',
    dist_abstract       => 'A secure way of running Perl methods on a remote server over SSH.',
    dynamic_config      => 0,
    requires => {
        'perl'              => '5.8.8',
        'JSON'              => '2.12',
        'Net::OpenSSH'      => '0.39',
        'Class::InsideOut'  => '1.06',
        },
);
$build->create_build_script;

