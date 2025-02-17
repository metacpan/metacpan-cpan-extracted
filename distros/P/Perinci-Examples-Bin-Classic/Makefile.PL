# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.014.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Perinci example CLI scripts (using Perinci::CmdLine::Classic)",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Perinci-Examples-Bin-Classic",
  "EXE_FILES" => [
    "script/peri-eg-append-file",
    "script/peri-eg-binary-files",
    "script/peri-eg-common-opts",
    "script/peri-eg-complete-fruits",
    "script/peri-eg-completion",
    "script/peri-eg-demo-cli-opts",
    "script/peri-eg-gen-random-bytes",
    "script/peri-eg-read-file",
    "script/peri-eg-write-file"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "Perinci::Examples::Bin::Classic",
  "PREREQ_PM" => {
    "Data::Sah::Coerce::perl::To_float::From_str::percent" => 0,
    "Data::Sah::Compiler::perl::TH::array" => 0,
    "Data::Sah::Compiler::perl::TH::bool" => 0,
    "Data::Sah::Compiler::perl::TH::buf" => 0,
    "Data::Sah::Compiler::perl::TH::float" => 0,
    "Data::Sah::Compiler::perl::TH::hash" => 0,
    "Data::Sah::Compiler::perl::TH::int" => 0,
    "Data::Sah::Compiler::perl::TH::str" => 0,
    "Data::Sah::Filter::perl::Path::expand_tilde_when_on_unix" => 0,
    "Data::Sah::Filter::perl::Path::strip_slashes_when_on_unix" => 0,
    "Perinci::CmdLine::Base" => "1.827",
    "Perinci::CmdLine::Classic" => "1.770",
    "Perinci::Examples" => "0.821",
    "Perinci::Examples::CLI" => 0,
    "Perinci::Examples::Completion" => 0,
    "Perinci::Examples::FileStream" => 0,
    "Sah::Schema::filename" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.081",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Sah::Coerce::perl::To_float::From_str::percent" => 0,
  "Data::Sah::Compiler::perl::TH::array" => 0,
  "Data::Sah::Compiler::perl::TH::bool" => 0,
  "Data::Sah::Compiler::perl::TH::buf" => 0,
  "Data::Sah::Compiler::perl::TH::float" => 0,
  "Data::Sah::Compiler::perl::TH::hash" => 0,
  "Data::Sah::Compiler::perl::TH::int" => 0,
  "Data::Sah::Compiler::perl::TH::str" => 0,
  "Data::Sah::Filter::perl::Path::expand_tilde_when_on_unix" => 0,
  "Data::Sah::Filter::perl::Path::strip_slashes_when_on_unix" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Perinci::CmdLine::Base" => "1.827",
  "Perinci::CmdLine::Classic" => "1.770",
  "Perinci::Examples" => "0.821",
  "Perinci::Examples::CLI" => 0,
  "Perinci::Examples::Completion" => 0,
  "Perinci::Examples::FileStream" => 0,
  "Sah::Schema::filename" => 0,
  "Test::More" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
