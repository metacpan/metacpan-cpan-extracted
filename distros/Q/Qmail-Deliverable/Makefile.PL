use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Qmail::Deliverable',
    VERSION_FROM      => 'lib/Qmail/Deliverable.pm', # finds $VERSION
    PREREQ_PM         => {},
    ABSTRACT_FROM  => 'lib/Qmail/Deliverable.pm', # retrieve abstract from module
    AUTHOR         => 'Juerd Waalboer <#####@juerd.nl>',
    EXE_FILES => [ "bin/qmail-deliverabled", "qpsmtpd-plugin/qmail_deliverable" ],
);
