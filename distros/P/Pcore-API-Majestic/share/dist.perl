{   name             => 'Pcore-API-Majestic',
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
    }
}
