use Module::Build;
Module::Build->new(
    module_name => 'Net::NAT::PMP',
    license     => 'perl',
    dist_author => 'David Caldwell <david@porkrind.org>',
    requires    => {
        IO::Socket::INET => 0,
    },
)->create_build_script;
