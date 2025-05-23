# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.023.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Insert/delete a line in a file (with undo support)",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Setup-File-Line",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "Setup::File::Line",
  "PREREQ_PM" => {
    "Exporter" => "5.57",
    "File::Slurper::Temp" => "0.008",
    "Log::ger" => "0.038",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Copy" => 0,
    "File::Path" => 0,
    "File::Slurper" => 0,
    "File::Spec" => 0,
    "File::Temp" => "0.2307",
    "File::chdir" => 0,
    "FindBin" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.98",
    "Test::Perinci::Tx::Manager" => "0.56"
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Exporter" => "5.57",
  "File::Copy" => 0,
  "File::Path" => 0,
  "File::Slurper" => 0,
  "File::Slurper::Temp" => "0.008",
  "File::Spec" => 0,
  "File::Temp" => "0.2307",
  "File::chdir" => 0,
  "FindBin" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Log::ger" => "0.038",
  "Test::More" => "0.98",
  "Test::Perinci::Tx::Manager" => "0.56",
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
