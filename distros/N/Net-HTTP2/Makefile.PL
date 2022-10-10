use ExtUtils::MakeMaker::CPANfile;

if (eval { require Net::SSLeay }) {
    if (!Net::SSLeay->can('CTX_set_alpn_protos')) {
        die sprintf "Net::SSLeay::CTX_set_alpn_protos() is missing; is your OpenSSL (%s) outdated?\n", Net::SSLeay::SSLeay_version(Net::SSLeay::SSLEAY_VERSION());
    }
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-Net-HTTP2.git',
                web => 'https://github.com/FGasper/p5-Net-HTTP2',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Net-HTTP2/issues',
            },
        },
    },

    NAME         => 'Net::HTTP2',
    AUTHOR       => 'Felipe Gasper (FELIPE)',
    VERSION_FROM => 'lib/Net/HTTP2.pm',         # finds \$VERSION
    ABSTRACT_FROM => 'lib/Net/HTTP2.pm',
    LICENSE      => 'perl_5',
);
