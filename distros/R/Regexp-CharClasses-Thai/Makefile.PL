use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Regexp::CharClasses::Thai',
    VERSION_FROM      => 'lib/Regexp/CharClasses/Thai.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    MIN_PERL_VERSION  => "5.008003",
    PREREQ_PM         => {
        "Exporter" => "5.57",
        "strict" => 0,
        "warnings" => 0,
        "utf8" => 0
        },
    ABSTRACT_FROM     => 'lib/Regexp/CharClasses/Thai.pm', # retrieve abstract from module
    AUTHOR            => 'Erik Mundall <emundall@biblasia.com>',
    LICENSE           => 'gpl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
);
