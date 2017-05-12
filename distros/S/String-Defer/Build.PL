use Module::Build;

Module::Build->new(
    module_name         => "String::Defer",
    license             => "bsd",
    configure_requires  => {
        "Module::Build"     => "0.38",
    },
    build_requires      => {
        "Test::More"        => "0.65",
        "Test::Exception"   => "0.31",
        "Test::Exports"     => "1",
    },
    requires            => {
        "Exporter"          => "5.57",
    },
    meta_merge          => {
        resources => {
            repository => "http://github.com/mauzo/String-Defer",
            bugtracker => "https://rt.cpan.org/Public/Dist/Display.html?Name=String-Defer",
        },
    },
)->create_build_script;
