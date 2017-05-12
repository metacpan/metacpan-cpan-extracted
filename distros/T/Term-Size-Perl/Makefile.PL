
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
#        EXTRA_META => "no_index:\n    file:\n        - inc/Probe.pm\n"
#        EXTRA_META => { recommends => { 'ExtUtils::Manifest' => 1.50 } },
    ) :()),

    PREREQ_PM     => {
        Exporter              => 0,
        ExtUtils::CBuilder    => 0, # build
        Test::More            => 0, # build
    }, 
    PM => {
        'Perl.pm' => '$(INST_LIBDIR)/Perl.pm',
        'Params.pm' => '$(INST_LIBDIR)/Perl/Params.pm'
    },
    clean => { FILES => "Params.pm" },

);
