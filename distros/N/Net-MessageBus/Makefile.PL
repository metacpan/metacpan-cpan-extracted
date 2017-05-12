use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::MessageBus',
    AUTHOR              => q{Horea Gligan <horea@gmail.com>},
    VERSION_FROM        => 'lib/Net/MessageBus.pm',
    ABSTRACT_FROM       => 'lib/Net/MessageBus.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'JSON'              => 0,
        'IO::Select'        => 0,
        'IO::Socket::INET'  => 0,
        'Log::Log4perl'     => 0,
        'Class::Accessor'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-MessageBus-*' },
);
