{   name             => '<: $dist_name :>',
    author           => '<: $author :> <<: $author_email :>>',
    license          => '<: $license :>',                        # https://metacpan.org/pod/Software::License#SEE-ALSO
    copyright_holder => '<: $copyright_holder :>',

    # CPAN distribution
    cpan => <: $cpan_distribution :>,

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
