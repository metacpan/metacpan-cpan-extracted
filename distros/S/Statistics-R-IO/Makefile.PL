# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.010.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "extras";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl interface to serialized R data",
  "AUTHOR" => "Davor Cubranic <cubranic\@stat.ubc.ca>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::ShareDir::Install" => "0.06"
  },
  "DISTNAME" => "Statistics-R-IO",
  "LICENSE" => "gpl",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "Statistics::R::IO",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Method::Modifiers" => 0,
    "Class::Tiny" => "1.001",
    "Class::Tiny::Antlers" => "0.023",
    "Math::Complex" => 0,
    "Scalar::Util" => 0,
    "namespace::clean" => "0.24"
  },
  "TEST_REQUIRES" => {
    "Test::Fatal" => 0,
    "Test::MockObject" => 0,
    "Test::MockObject::Extends" => 0,
    "Test::More" => "0.96"
  },
  "VERSION" => "1.0002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Class::Method::Modifiers" => 0,
  "Class::Tiny" => "1.001",
  "Class::Tiny::Antlers" => "0.023",
  "Math::Complex" => 0,
  "Scalar::Util" => 0,
  "Test::Fatal" => 0,
  "Test::MockObject" => 0,
  "Test::MockObject::Extends" => 0,
  "Test::More" => "0.96",
  "namespace::clean" => "0.24"
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
