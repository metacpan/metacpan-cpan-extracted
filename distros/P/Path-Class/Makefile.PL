
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Cross-platform path specification manipulation",
  "AUTHOR" => "Ken Williams <kwilliams\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Path-Class",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Path::Class",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Cwd" => 0,
    "Exporter" => 0,
    "File::Copy" => 0,
    "File::Path" => 0,
    "File::Spec" => "3.26",
    "File::Temp" => 0,
    "File::stat" => 0,
    "IO::Dir" => 0,
    "IO::File" => 0,
    "Perl::OSType" => 0,
    "Scalar::Util" => 0,
    "overload" => 0,
    "parent" => 0,
    "strict" => 0
  },
  "TEST_REQUIRES" => {
    "Test" => 0,
    "Test::More" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.37",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Cwd" => 0,
  "Exporter" => 0,
  "File::Copy" => 0,
  "File::Path" => 0,
  "File::Spec" => "3.26",
  "File::Temp" => 0,
  "File::stat" => 0,
  "IO::Dir" => 0,
  "IO::File" => 0,
  "Module::Build" => "0.3601",
  "Perl::OSType" => 0,
  "Scalar::Util" => 0,
  "Test" => 0,
  "Test::More" => 0,
  "overload" => 0,
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



