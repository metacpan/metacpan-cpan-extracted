use strict;
use warnings;
use ExtUtils::MakeMaker 6.48;

my %options = (
  NAME          => 'Net::Google::Analytics::MeasurementProtocol',
  AUTHOR        => 'Breno G. de Oliveira <garu@cpan.org>',
  VERSION_FROM  => 'lib/Net/Google/Analytics/MeasurementProtocol.pm',
  ABSTRACT_FROM => 'lib/Net/Google/Analytics/MeasurementProtocol.pm',
  MIN_PERL_VERSION => 5.020000,
  LICENSE       => 'perl',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More' => 0.88,
    'Carp'       => 0,
    'Furl'       => 0,
    'JSON'       => 0,
  },
  META_MERGE      => {
    resources => {
      license     => 'http://dev.perl.org/licenses/',
      bugtracker  => 'http://github.com/garu/Net-Google-Analytics-MeasurementProtocol/issues',
      repository  => 'http://github.com/garu/Net-Google-Analytics-MeasurementProtocol',
    },
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Net-Google-Analytics-MeasurementProtocol-*' },
);

WriteMakefile( %options );

