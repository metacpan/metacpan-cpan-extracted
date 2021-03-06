# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.003.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "(DEPRECATED) Postfilter function result",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Perinci-Sub-Property-result_postfilter",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "Perinci::Sub::Property::result_postfilter",
  "PREREQ_PM" => {
    "Perinci::Sub::PropertyUtil" => "0.11",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "DateTime" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Perinci::Sub::Wrapper" => "0.57",
    "Test::More" => "0.98",
    "Test::Perinci::Sub::Wrapper" => "0.57"
  },
  "VERSION" => "0.10",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "DateTime" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Perinci::Sub::PropertyUtil" => "0.11",
  "Perinci::Sub::Wrapper" => "0.57",
  "Test::More" => "0.98",
  "Test::Perinci::Sub::Wrapper" => "0.57",
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
