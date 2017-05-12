
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Run command-line sessions to network appliances",
  "AUTHOR" => "Oliver Gorwits <oliver\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Appliance-Session",
  "EXE_FILES" => [
    "bin/nas"
  ],
  "LICENSE" => "perl",
  "NAME" => "Net::Appliance::Session",
  "PREREQ_PM" => {
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "Getopt::Long" => "2.24",
    "IO::Handle" => 0,
    "IO::Prompt::Tiny" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "Net::CLI::Interact" => "2.200005",
    "Sub::Quote" => 0,
    "Term::ANSIColor" => 0,
    "Term::ReadPassword" => 0,
    "Text::Glob" => 0,
    "Text::ParseWords" => 0,
    "Try::Tiny" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "4.200003",
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



