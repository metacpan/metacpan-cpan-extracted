use strict;
use warnings;

use 5.008000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  VERSION_FROM => "lib/Respite.pm",
  ABSTRACT_FROM => "lib/Respite.pm",
  AUTHOR => 'Paul Seamons <paul\@seamons.com>, Jason Hall <jayce@cpan.org>, Rob Brown <hookbot@github.com>',
  CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => 0,
  },
  DISTNAME => "Respite",
  LICENSE => "perl",
  MIN_PERL_VERSION => "5.008000",
  NAME => "Respite",
  PREREQ_PM => {
    "CGI::Ex" => 0,
    "Data::Debug" => 0,
    "Digest::MD5" => 0,
    "End" => 0,
    "FindBin" => 0,
    "IO::Interactive" => 0,
    "IO::Socket::SSL" => 0,
    "JSON" => 0,
    "Net::Server" => 0,
    "Scalar::Util" => 0,
    "Text::PrettyTable" => 0.03,
    "Throw" => 0,
    "Time::HiRes" => 0,
  },
  TEST_REQUIRES => {
    "Test::Deep" => 0,
  },
);


my %FallbackPrereqs = (
  "CGI::Ex" => 0,
  "Data::Debug" => 0,
  "Digest::MD5" => 0,
  "End" => 0,
  "FindBin" => 0,
  "IO::Interactive" => 0,
  "IO::Socket::SSL" => 0,
  "JSON" => 0,
  "Net::Server" => 0,
  "Scalar::Util" => 0,
  "Test::Deep" => 0,
  "Throw" => 0,
  "Time::HiRes" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
