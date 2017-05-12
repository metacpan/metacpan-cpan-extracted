{   name             => 'Pcore-API-Namecheap',
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
    },

    # shared resources, used by modules in this distribution
    mod_share => {

        # eg.:
        # 'Distribution/Module/Name.pm' => ['/data/cfg.perl', '/data/cfg.ini'],
    },
}
