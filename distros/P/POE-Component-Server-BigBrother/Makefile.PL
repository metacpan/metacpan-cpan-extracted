use strict;
use ExtUtils::MakeMaker;
use File::Spec::Functions;


# regenerate README
if (eval "use Pod::Text; 1") {
    my $parser = Pod::Text->new;
    $parser->parse_from_file(catfile(qw(lib POE Component Server BigBrother.pm)), "README");
}

WriteMakefile(
    NAME          => 'POE::Component::Server::BigBrother',
    AUTHOR        => 'Yves Blusseau',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/POE/Component/Server/BigBrother.pm',
    ABSTRACT_FROM => 'lib/POE/Component/Server/BigBrother.pm',
    PREREQ_PM     => {
                   # prereqs
                   'Carp'                                 => 0,
                   'POE'                                  => '0.38',
                   'POE::Component::Server::TCP'          => 0,
                   'POE::Component::Pluggable'            => 0,
                   'POE::Component::Pluggable::Constants' => 0,
                   'POE::Filter::Stream'                  => '1.2220',
                   'POE::Filter::BigBrother'              => '0.12',
                   'Log::Report'                          => '0.18',

                   # build/test prereqs
                   'Test::More'                           => '0.60',
                 },

    PL_FILES      => {},
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
        PREOP =>
          q{ $(NOECHO) $(PERL) tools/disable_smart_comments -verbose -distdir=$(DISTVNAME) $(TO_INST_PM) }
    },
    clean => { FILES => 'POE-Component-Server-BigBrother-*' }
);
