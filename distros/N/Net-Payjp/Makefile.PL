use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Net::Payjp',
  AUTHOR => 'Payjp',
  VERSION_FROM  => 'lib/Net/Payjp.pm',
  LICENSE => 'perl_5',
  PREREQ_PM => {
    'LWP::UserAgent' => 0,
    'LWP::Protocol::https' => 0,
    'HTTP::Request::Common' => 0,
    'JSON' => 0,
    'Test::More' => 0
  }
);
