use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Printer::HP::Display',
    AUTHOR              => q{Deepak Gulati <deepak.gulati@gmail.com>},
    VERSION_FROM        => 'lib/Printer/HP/Display.pm',
    ABSTRACT_FROM       => 'lib/Printer/HP/Display.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'IO::Socket::INET' => 0,
		'Encode' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Printer-HP-Display-*' },
);
