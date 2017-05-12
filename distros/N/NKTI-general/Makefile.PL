
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'NKTI::general',
    VERSION_FROM      => 'lib/NKTI/general.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'Test::More' => 0,
        'JSON' => 0,
        'DBI' => 0,
        'Data::Dumper' => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Request::Common' => 0,
        'CGI' => 0,
        'DateTime' => 0,
        'HTTP::BrowserDetect' => 0,
    }, # e.g., Module::Name => 1.1
#    ABSTRACT_FROM     => 'lib/NKTI/general.pm', # retrieve abstract from module
    AUTHOR            => 'Achmad Yusri Afandi <yusrideb@cpan.org>',
    LICENSE           => 'perl_5',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);