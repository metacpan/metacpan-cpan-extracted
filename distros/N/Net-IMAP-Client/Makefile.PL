use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::IMAP::Client',
    AUTHOR              => 'Mihai Bazon <mihai.bazon@gmail.com>',
    VERSION_FROM        => 'lib/Net/IMAP/Client.pm',
    ABSTRACT_FROM       => 'lib/Net/IMAP/Client.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'           => 0,
        'IO::Socket::INET'     => 0,
        'IO::Socket::SSL'      => 0,
        'List::Util'           => 0,
        'List::MoreUtils'      => 0,
        'Encode'               => 0,
        'Encode::MIME::Header' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-IMAP-Client-*' },
);
