use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Bot::IRC::NumericCodes',
    AUTHOR              => q{Mark Caudill <mcaudill@cpan.org>},
    VERSION_FROM        => 'lib/Net/Bot/IRC/NumericCodes.pm',
    ABSTRACT_FROM       => 'lib/Net/Bot/IRC/NumericCodes.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Bot-IRC-NumericCodes-*' },
);
