
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "an unmaintained set of Plucene backends for indexing Microsoft Office formats",
  "AUTHOR" => "Sopan Shewale <sopan.shewale\@gmail.com>, Mike Doherty <doherty\@pythian.com>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Plucene-SearchEngine-Index-MSOffice",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Plucene::SearchEngine::Index::MSOffice",
  "PREREQ_PM" => {
    "File::Temp" => 0,
    "IPC::Run3" => 0,
    "Plucene::SearchEngine::Index::Base" => 0,
    "Plucene::SearchEngine::Index::HTML" => 0,
    "Plucene::SearchEngine::Index::Text" => 0,
    "Spreadsheet::ParseExcel" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



