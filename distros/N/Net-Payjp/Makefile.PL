use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
  NAME => 'Net::Payjp',
  AUTHOR => 'Payjp',
  VERSION_FROM  => 'lib/Net/Payjp.pm',
  LICENSE => 'perl_5',
  PREREQ_PM => {
    'LWP::UserAgent' => 0,
    'LWP::Protocol::https' => 0,
    'HTTP::Request::Common' => 0,
    'JSON' => 0,
  },
  'test' => { 'TESTS' => 't/*.t' },
);
my %test_requires = (
  'Test::More' => 0,
  'Test::Mock::LWP' => 0,
);

if (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
	$conf{TEST_REQUIRES} = \%test_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %test_requires);
}

WriteMakefile(%conf);
