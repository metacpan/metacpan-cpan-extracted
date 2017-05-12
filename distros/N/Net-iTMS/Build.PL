use Module::Build;

Module::Build->new(
    module_name         => 'Net::iTMS',
    dist_version        => '0.15',
    dist_author         => 'Thomas Sibley, http://zulutango.org:82/',
    dist_abstract       => 'Interface to the iTunes Music Store (iTMS)',
    license             => 'perl',

    # I don't know the earliest module versions that will
    # work... sorry
    requires            => {
        'LWP::UserAgent'    => 0,
        'HTTP::Request'     => 0,
        'Crypt::CBC'        => 0,
        'Crypt::Rijndael'   => 0,
        'Digest::MD5'       => 0,
        'Compress::Zlib'    => 0,
        'XML::Twig'         => 0,
        'Exporter::Lite'    => 0,
        'URI::Escape'       => 0,
    },    
    build_requires => {
        'Test::More'        => 0,
    },
    create_makefile_pl  => 'traditional',
)->create_build_script;
