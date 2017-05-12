use Module::Build;
my $build = Module::Build->new(
    license            => 'perl',
    dist_author        => 'Dave Cross <dave@mag-sol.com>',
    module_name        => 'Net::Songkick',
    license            => 'perl',
    requires           => {
        perl                       => '5.6.0',
        LWP::UserAgent             => 0,
        Moose                      => 0,
        XML::LibXML                => 0,
        URI                        => 0,
        JSON                       => 0,
        DateTime::Format::Strptime => 0,
    },
    build_recommends   => {
        Test::Pod           => 0,
        Test::Pod::Coverage => 0,
    },
    create_makefile_pl => 'traditional',
    script_files       => [ 'bin/gigs' ],
    meta_merge         => {
        resources => {
            repository => 'https://github.com/davorg/net-songkick',
        },
    },
);

$build->create_build_script;

