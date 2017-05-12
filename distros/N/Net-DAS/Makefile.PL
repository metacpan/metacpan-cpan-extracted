use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Net::DAS',
    VERSION_FROM    => 'lib/Net/DAS.pm',
    AUTHOR          => 'Michael Holloway <michael@thedarkwinter.com>',
    PREREQ_PM       => { 'Test::More'=>0, 'Module::Load'=>0, 'IO::Socket'=>0, 'IO::Socket::INET'=>0, 'Time::HiRes'=>0 },
    dist            => { COMPRESS => 'gzip', SUFFIX => '.gz', },
    EXE_FILES       => [ 'bin/das' ],
);
