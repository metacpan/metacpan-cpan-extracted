
use 5;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

# a target to run the probe (which generates Params.pm)
sub MY::postamble {
    return <<'MAKE_FRAG';

Params.pm: inc/Probe.pm
	$(PERL) inc/Probe.pm

MAKE_FRAG
}

WriteMakefile(
    NAME => 'Term::Size::Perl',
    VERSION_FROM => 'Perl.pm',
    ($] >= 5.005 ? (
        'ABSTRACT_FROM' => 'Perl.pm',
        'AUTHOR'        => 'Adriano R. Ferreira <ferreira@cpan.org>'
    ) : ()),
    ($EUMM_VERSION >= 6.31 ? (
        LICENSE => 'perl',
    ) :()),
    ($EUMM_VERSION >= 6.46 ? (
        META_MERGE => {
            'dynamic_config' => 0,
            'meta-spec'      => { version => 2 },
            'prereqs' => {
                configure =>
                  { recommends => { 'ExtUtils::Manifest' => '1.50' } },
                develop => {
                    requires => {
                        'Test::Pod'           => '1.18',
                        'Test::Pod::Coverage' => '1.04',
                    }
                },
            },
            'resources'      => {
                repository => {
                    type => 'git',
                    url  => 'git://github.com/aferreira/cpan-Term-Size-Perl.git',
                    web  => 'https://github.com/aferreira/cpan-Term-Size-Perl'
                },
            },
            'no_index'       => { file => ['inc/Probe.pm'] },
        },
        TEST_REQUIRES => {
            'Test::More' => '0',
        },
    ) : ()),
    ($EUMM_VERSION >= 6.5503 ? (
        BUILD_REQUIRES => {
            'ExtUtils::CBuilder' => '0',
        },
    ) : ()),

    PREREQ_PM     => {
        'Exporter'            => '0',
      ( 'Test::More'          => '0' ) x !!($EUMM_VERSION < 6.46),
      ( 'ExtUtils::CBuilder'  => '0' ) x !!($EUMM_VERSION < 6.5503),
    },
    PM => {
        'Perl.pm'   => '$(INST_LIBDIR)/Perl.pm',
        'Params.pm' => '$(INST_LIBDIR)/Perl/Params.pm'
    },
    clean => { FILES => "Params.pm" },
);
