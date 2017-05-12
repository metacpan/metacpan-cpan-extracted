
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Almost all of the modules required for installing OTRS Help Desk on win32.",
  "AUTHOR" => "Michiel Beijen <michiel.beijen\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-OTRS-Win32",
  "EXE_FILES" => [],
  "LICENSE" => "open_source",
  "NAME" => "Task::OTRS::Win32",
  "PREREQ_PM" => {
    "Date::Manip" => 0,
    "Log::Dispatch" => 0,
    "Log::Dispatch::FileRotate" => 0,
    "Log::Log4perl" => 0,
    "Module::Build" => "0.39",
    "Task::OTRS" => "1.04",
    "Win32" => 0,
    "Win32::Console::ANSI" => 0,
    "Win32::Daemon" => 0,
    "Win32::Service" => 0
  },
  "VERSION" => "1.12",
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



