use 5.030000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::EANSearch',
    VERSION_FROM      => 'lib/Net/EANSearch.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => { 'WWW::Curl::Easy' => 0, 'JSON' => 0, 'URL::Encode' => 0, 'MIME::Base64' => 0 },
    ABSTRACT_FROM     => 'lib/Net/EANSearch.pm', # retrieve abstract from module
    AUTHOR            => 'Jan Willamowius <jan@willamowius.de>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
