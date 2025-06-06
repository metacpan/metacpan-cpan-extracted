# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.024.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Append an index file to request PATH's ending with a /",
  "AUTHOR" => "Leo Lapworth",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Plack-Middleware-DirIndex",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Plack::Middleware::DirIndex",
  "PREREQ_PM" => {
    "Plack::Middleware" => 0,
    "Plack::Util::Accessor" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "Plack::App::Directory" => 0,
    "Plack::App::File" => 0,
    "Plack::Builder" => 0,
    "Plack::Middleware::ErrorDocument" => 0,
    "Plack::Test" => 0,
    "Test::More" => 0,
    "lib" => 0
  },
  "VERSION" => "1.01",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::Spec" => 0,
  "Plack::App::Directory" => 0,
  "Plack::App::File" => 0,
  "Plack::Builder" => 0,
  "Plack::Middleware" => 0,
  "Plack::Middleware::ErrorDocument" => 0,
  "Plack::Test" => 0,
  "Plack::Util::Accessor" => 0,
  "Test::More" => 0,
  "lib" => 0,
  "parent" => 0,
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
