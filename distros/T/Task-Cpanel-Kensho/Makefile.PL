
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Provides all of Task::Kensho bundles including ones considered optional.",
  "AUTHOR" => "cPanel <cpanel\@cpan.org>",
  "BUILD_REQUIRES" => {
    "FindBin" => 0,
    "Test::More" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-Cpanel-Kensho",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Task::Cpanel::Kensho",
  "PREREQ_PM" => {
    "Task::Kensho::Async" => 0,
    "Task::Kensho::CLI" => 0,
    "Task::Kensho::Config" => 0,
    "Task::Kensho::DBDev" => 0,
    "Task::Kensho::Dates" => 0,
    "Task::Kensho::Email" => 0,
    "Task::Kensho::ExcelCSV" => 0,
    "Task::Kensho::Exceptions" => 0,
    "Task::Kensho::Hackery" => 0,
    "Task::Kensho::Logging" => 0,
    "Task::Kensho::ModuleDev" => 0,
    "Task::Kensho::OOP" => 0,
    "Task::Kensho::Scalability" => 0,
    "Task::Kensho::Testing" => 0,
    "Task::Kensho::Toolchain" => 0,
    "Task::Kensho::WebCrawling" => 0,
    "Task::Kensho::WebDev" => 0,
    "Task::Kensho::XML" => 0,
    "strict" => 0
  },
  "VERSION" => "11.36.001",
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



