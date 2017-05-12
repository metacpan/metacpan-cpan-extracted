use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Sendmail::AccessDB',
    VERSION_FROM => 'lib/Sendmail/AccessDB.pm', # finds $VERSION
    AUTHOR       => 'Derek J. Balling (dredd@megacity.org)',
    ABSTRACT     => 'An interface to Sendmail access.db',
    PREREQ_PM   => {
	'BerkeleyDB'=> '0'
    },
    clean        => {FILES => "t/test.db" }
);
