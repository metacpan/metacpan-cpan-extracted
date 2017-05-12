use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Net::ADNS',
               VERSION_FROM => 'lib/Net/ADNS.pm',
               PREREQ_PM => { Test::More },
               ABSTRACT_FROM => 'lib/Net/ADNS.pm',
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS => ['-ladns'],
               DEFINE => '',
               INC => '-I.',
               depend => { '$(BASEEXT).c' => 'constants.h' }  );

sub MY::postamble {
    return <<MAKE_FRAG

constants.h: genconstants constants.data
\t\$(PERL) genconstants constants.data > constants.h

MAKE_FRAG

}
