use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::SMS::O2_DE',
    AUTHOR              => q{Stefan Profanter <profanter@cpan.org>},
    VERSION_FROM        => 'lib/Net/SMS/O2_DE.pm',
    ABSTRACT_FROM       => 'lib/Net/SMS/O2_DE.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::More' => 0,
        'Crypt::SSLeay'   => 0,
        'Net::SMS::Web'   => 0,
        'URI::Escape'     => 0,
		'Time::Local'	  => 0,
		'Date::Format'	  => 0,,
		'POSIX'	  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-SMS-O2_DE-*' },
);
