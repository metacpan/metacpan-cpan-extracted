use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::SMS::160By2',
    AUTHOR              => q{Mohan Prasad Gutta <mohanprasadgutta@gmail.com>},
    VERSION_FROM        => 'lib/Net/SMS/160By2.pm',
    ABSTRACT_FROM       => 'lib/Net/SMS/160By2.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'WWW::Mechanize' => 0,
        'HTML::Form' => 0,
        'Data::Dumper' => 0,
        'POSIX' => 0,
        'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-SMS-160By2-*' },
);
