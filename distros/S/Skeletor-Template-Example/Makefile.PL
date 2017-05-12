use strict;
use warnings;
 
use 5.008001;
use ExtUtils::MakeMaker 6.30;
use File::ShareDir::Install;
install_share dist => "share";

my %WriteMakefileArgs = (
  "ABSTRACT" => "Example Project Template for Skeletor",
  "AUTHOR" => "John Napiorkowski",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Skeletor-Template-Example",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008001",
  "NAME" => "Skeletor::Template::Example",
  "PREREQ_PM" => {
    "File::ShareDir" => 0,
  },
  "TEST_REQUIRES" => {
    "Test::Most" => 0
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);
 
my %FallbackPrereqs = (
  "File::ShareDir" => 0,
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
