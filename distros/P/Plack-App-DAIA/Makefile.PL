
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "DAIA Server as Plack application",
  "AUTHOR" => "Jakob Vo\x{df}",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Plack-App-DAIA",
  "EXE_FILES" => [
    "bin/provedaia"
  ],
  "LICENSE" => "perl",
  "NAME" => "Plack::App::DAIA",
  "PREREQ_PM" => {
    "CGI" => 0,
    "DAIA" => "0.43",
    "File::ShareDir" => 0,
    "File::Spec::Functions" => 0,
    "Getopt::Long" => 0,
    "HTTP::Request::Common" => 0,
    "JSON" => 0,
    "LWP::Simple" => 0,
    "Plack" => "1.0",
    "Pod::Usage" => 0,
    "Test::Builder::Module" => 0,
    "Test::JSON::Entails" => 0,
    "Try::Tiny" => 0,
    "URI::Escape" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Warn" => 0
  },
  "VERSION" => "0.55",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "CGI" => 0,
  "DAIA" => "0.43",
  "File::ShareDir" => 0,
  "File::Spec::Functions" => 0,
  "Getopt::Long" => 0,
  "HTTP::Request::Common" => 0,
  "JSON" => 0,
  "LWP::Simple" => 0,
  "Plack" => "1.0",
  "Pod::Usage" => 0,
  "Test::Builder::Module" => 0,
  "Test::JSON::Entails" => 0,
  "Test::Warn" => 0,
  "Try::Tiny" => 0,
  "URI::Escape" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


