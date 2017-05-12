use Module::Build;
use version;
$build = Module::Build->new(
    dist_author        => 'Martin Kutter <martin.kutter@fen-net.de>',
    create_makefile_pl => 'small',
    dist_abstract      => 'JABBER support for SOAP::Lite',
    dist_name          => 'SOAP-Transport-JABBER',
    dist_version       => '0.713',
    module_name        => 'SOAP::Transport::JABBER',
    license            => 'artistic',
    requires           => {
        'perl'         => q(5.6.0),
        'SOAP::Lite'   => 0.711,
        'Net::Jabber'  => 0
    },
    build_requires => {
        'Test::More'              => 0,
    },
    recursive_test_files => 1,
    meta_add => {
    }
);
$build->create_build_script;
