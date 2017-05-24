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
    ]
}
