use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::EANSearch',
    VERSION_FROM      => 'lib/Net/EANSearch.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => { 'LWP' => 0, 'JSON' => 0, 'URL::Encode' => 0, 'MIME::Base64' => 0, 'Test::NoWarnings' => 0 },
    ABSTRACT_FROM     => 'lib/Net/EANSearch.pm', # retrieve abstract from module
    AUTHOR            => 'Jan Willamowius <jan@willamowius.de>',
    LICENSE           => 'perl',
	MIN_PERL_VERSION  => '5.8.9',
    META_MERGE        => {
        'meta-spec' => { 'version' => 2 },
         'resources' => {
             'repository' => {
                 'type' => 'git',
                 'url'  => 'https://github.com/eansearch/perl-ean-search.git',
                 'web'  => 'https://github.com/eansearch/perl-ean-search',
             },
             'bugtracker' => {
                 'web' => 'https://github.com/eansearch/perl-ean-search/issues',
             },
        },
    },
);
