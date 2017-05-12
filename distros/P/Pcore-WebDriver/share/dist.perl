{   name             => 'Pcore-WebDriver',
    author           => 'zdm <zdm@softvisio.net>',
    license          => 'Perl_5',                    # https://metacpan.org/pod/Software::License#SEE-ALSO
    copyright_holder => 'zdm',

    # CPAN distribution
    cpan => 1,

    # files to ignore in CPAN distribution
    cpan_manifest_skip => [

        # eg.:
        # qr[\Ashare/data/.+[.]dat\z]smi,
        # qr[\Abin/]smi,    # ignore "/bin/" directory

        qr[\Ashare/bin/webdriver/]smi,
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

        'Pcore/WebDriver/PhantomJS.pm' => ['/bin/webdriver/phantomjs.exe'],
        'Pcore/WebDriver/Chrome.pm'    => ['/bin/webdriver/chromedriver.exe'],
        'Pcore/WebDriver/Firefox.pm'   => ['/bin/webdriver/geckodriver.exe'],
    },

    phantomjs_ver    => '2.1.1',
    chromedriver_ver => '2.29',
    geckodriver_ver  => '0.16.1',
    ff_ver           => '53.0',
}
