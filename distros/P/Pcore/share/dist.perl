{   name             => 'Pcore',
    author           => 'zdm <zdm@cpan.org>',
    license          => 'Perl_5',
    copyright_holder => 'zdm',

    # CPAN distribution
    cpan => 1,

    # files to ignore in CPAN distribution
    cpan_manifest_skip => [

        # eg.:
        # qr[\Ashare/data/.+[.]dat\z]smi,
        # qr[\Abin/]smi,    # ignore "/bin/" directory

        qr[\Ashare/data/tld[.]dat\z]smi,
        qr[\Ashare/data/pub_suffix[.]dat\z]smi,
    ],

    # Pcore utils, provided by this distribution
    util => {

        # eg.:
        # util_accessor_name => 'Util::Package::Name'
        # and later in the code you can use P->util_accessor_name->...
    },

    # shared resources, used by modules in this distribution
    mod_share => {
        'Pcore/Dist/Build/Deploy.pm' => ['/data/pcore.perl'],
        'Pcore/Dist/Build/PAR'       => ['/data/pcore.perl'],
        'Pcore/Src/File.pm'          => ['/data/src.perl'],
        'Pcore/Util/CA.pm'           => ['/data/ca_file.pem'],
        'Pcore/Util/Path.pm'         => ['/data/mime.json'],
        'Pcore/Util/URI/Host.pm'     => [ '/data/pub_suffix.dat', '/data/tld.dat' ],
        'Pcore/Util/URI/Web2.pm'     => ['/data/web2.ini'],
    },
}
