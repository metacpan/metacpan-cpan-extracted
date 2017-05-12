use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Google::SafeBrowsing::UpdateRequest',
    AUTHOR              => 'Dan Born <danborn@cpan.org>',
    VERSION_FROM        => 'lib/Net/Google/SafeBrowsing/UpdateRequest.pm',
    ABSTRACT_FROM       => 'lib/Net/Google/SafeBrowsing/UpdateRequest.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Pod' => 0,
        'File::Temp' => 0,
        'fields' => 0,
        'LWP::UserAgent' => 0,
        'English' => 0,
        'Fcntl' => 0,
        'Digest::MD5' => 0,
        'MIME::Base64' => 0,
        'DB_File' => 0,
        'Net::Google::SafeBrowsing::Blocklist' => 0,
    },
    EXE_FILES           => ['blocklist_updater', ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Google-SafeBrowsing-UpdateRequest-*' },
);
