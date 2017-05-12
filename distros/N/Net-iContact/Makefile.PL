use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::iContact',
    AUTHOR              => 'Ian Kilgore <ian@icontact.com>',
    VERSION_FROM        => 'lib/Net/iContact.pm',
    ABSTRACT_FROM       => 'lib/Net/iContact.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Digest::MD5' => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Request::Common' => 0,
        'XML::Bare' => 0,
        'XML::Generator' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-iContact-*' },
);
