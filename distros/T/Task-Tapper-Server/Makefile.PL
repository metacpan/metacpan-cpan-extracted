
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tapper - dependencies for central server",
  "AUTHOR" => "AMD OSRC Tapper Team <tapper\@amd64.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-Tapper-Server",
  "EXE_FILES" => [],
  "LICENSE" => "open_source",
  "NAME" => "Task::Tapper::Server",
  "PREREQ_PM" => {
    "DBD::Pg" => 0,
    "DBD::SQLite" => 0,
    "DBD::mysql" => 0,
    "DBI" => 0,
    "File::Copy::Recursive" => 0,
    "File::Slurp" => 0,
    "IO::Interactive" => 0,
    "Module::Install::Catalyst" => 0,
    "Tapper::CLI" => 0,
    "Tapper::Config" => 0,
    "Tapper::Reports::API" => 0,
    "Tapper::Reports::Receiver" => 0,
    "Tapper::Reports::Web" => 0,
    "Tapper::TAP::Harness" => 0,
    "Tapper::Testplan" => 0,
    "Template::Plugin::Autoformat" => 0,
    "Test::WWW::Mechanize" => 0,
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



