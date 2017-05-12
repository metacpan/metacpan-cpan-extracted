# $id$

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'POE::Component::Client::POP3',
    PM           => { 'POP3.pm' => '$(INST_LIBDIR)/POP3.pm' },
    VERSION_FROM => 'POP3.pm',
    dist         => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz'
    },
    PREREQ_PM    => {
        POE    => 0.17,
        Carp   => 0,
        Socket => 0
    },
    ($^O ne 'MacOS' ?
      (ABSTRACT_FROM => 'POP3.pm',
       AUTHOR     => 'Scott A. Beck <scott@gossamer-threads.com>') : ()),
);
