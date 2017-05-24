{   name             => 'Pcore-DBH',
    author           => 'zdm <zdm@softvisio.net>',
    license          => 'Perl_5',                    # https://metacpan.org/pod/Software::License#SEE-ALSO
    copyright_holder => 'zdm',

    # CPAN distribution
    cpan => 1,

    # files to ignore in CPAN distribution
    cpan_manifest_skip => [

        # eg.:
        # qr[\Ashare/data/.+[.]dat\z]smi,
        qr[\Abin/]smi,    # ignore "/bin/" directory
    ],

    meta => {
        homepage   => undef,    # project homepage url
        repository => {
            web  => undef,      # repository web url
            url  => undef,      # repository clone url
            type => undef,      # hg, git
        },
        bugtracker => {
            web => undef,       # bugtracker url
        }
    }
}
