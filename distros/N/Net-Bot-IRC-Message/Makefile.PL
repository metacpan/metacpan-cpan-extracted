use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Bot::IRC::Message',
    AUTHOR              => q{Mark Caudill <mcaudill@cpan.org>},
    VERSION_FROM        => 'lib/Net/Bot/IRC/Message.pm',
    ABSTRACT_FROM       => 'lib/Net/Bot/IRC/Message.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
        'Params::Validate' => 0.95,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Bot-IRC-Message-*' },
);
