use Module::Build;
use version;
$build = Module::Build->new(
    dist_author        => 'Martin Kutter <martin.kutter@fen-net.de>',
    create_makefile_pl => 'small',
    dist_abstract      => 'MQ support for SOAP::Lite',
    dist_name          => 'SOAP-Transport-FTP',
    dist_version       => 0.711,
    module_name        => 'SOAP::Transport::FTP',
    license            => 'artistic',
    requires           => {
        'perl'         => q(5.6.0),
        'SOAP::Lite'   => 0.711,
        'Net::FTP'     => 0,
        'IO::File'     => 0,
    },
    build_requires => {
        'Test::More'              => 0,
    },
    recursive_test_files => 1,
    meta_add => {
    }
);
$build->create_build_script;
