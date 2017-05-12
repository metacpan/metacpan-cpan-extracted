{   name             => 'Pcore-GeoIP',
    author           => 'zdm <zdm@softvisio.net>',
    license          => 'Perl_5',
    copyright_holder => 'zdm',

    # CPAN distribution
    cpan => 1,

    # files to ignore in CPAN distribution
    cpan_manifest_skip => [

        # eg.:
        # qr[\Ashare/data/.+[.]dat\z]smi,
        # qr[\Abin/]smi,    # ignore "/bin/" directory

        qr[\Ashare/data/geoip.+[.](?:dat|mmdb)\z]smi,
    ],

    meta => {
        homepage   => undef,
        repository => {
            web  => undef,
            url  => undef,
            type => undef,
        },
        bugtracker => {    #
            web => undef,
        }
    },

    # Pcore utils, provided by this distribution
    util => {

        # eg.:
        # util_accessor_name => 'Util::Package::Name'
        # and later in the code you can use P->util_accessor_name->...

        geoip => 'Pcore::Util::GeoIP',
    },

    # shared resources, used by modules in this distribution
    mod_share => {

        # eg.:
        # 'Distribution/Module/Name.pm' => ['/data/cfg.perl', '/data/cfg.ini'],

        'Pcore/Util/GeoIP.pm' => [    #
            '/data/geoip_country.dat',
            '/data/geoip_country_v6.dat',
            '/data/geoip_city.dat',
            '/data/geoip_city_v6.dat',
            '/data/geoip2_country.mmdb',
            '/data/geoip2_city.mmdb',
        ],
    },
}
