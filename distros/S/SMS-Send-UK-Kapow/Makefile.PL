use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SMS::Send::UK::Kapow',
    AUTHOR              => 'Jeremy Jones <jjones@cpan.org>',
    VERSION_FROM        => 'lib/SMS/Send/UK/Kapow.pm',
    ABSTRACT_FROM       => 'lib/SMS/Send/UK/Kapow.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'          => 0,
        'MIME::Lite'          => 0,
        'LWP::UserAgent'      => 0,
        'SMS::Send::Driver'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SMS-Send-UK-Kapow-*' },
);
