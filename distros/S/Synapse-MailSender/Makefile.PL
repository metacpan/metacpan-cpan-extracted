use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Synapse::MailSender',
    VERSION_FROM => './lib/Synapse/MailSender.pm',
    PREREQ_PM => { # we assume any reasonably not too-old version should work
        "MIME::Lite"            => 3.0,
        "MIME::Type::FileName"  => 1.0,
        "XML::Parser::REX"      => 1.01,
        "Petal::Tiny"           => 1.03,
        "YAML::XS"              => 0.38,
	"Synapse::Logger"	=> 0.1,
    },
    EXE_FILES => [ './scripts/synapse-mailsender' ],
);
