
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "App to generate Cisco NetFlow from Linux netfilter",
  "AUTHOR" => "Oliver Gorwits <oliver\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Netfilter-NetFlow",
  "EXE_FILES" => [
    "bin/nfflowd"
  ],
  "LICENSE" => "perl",
  "NAME" => "Net::Netfilter::NetFlow",
  "PREREQ_PM" => {
    "Config" => 0,
    "Config::Any" => "0.15",
    "Config::General" => 0,
    "Daemon::Generic" => 0,
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Slurp" => "9999.06",
    "File::Spec" => 0,
    "Getopt::Long" => 0,
    "IPC::Run" => 0,
    "Log::Dispatch::Config" => 0,
    "Log::Dispatch::Configurator::Any" => 0,
    "POSIX" => 0,
    "Time::HiRes" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.113260",
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



