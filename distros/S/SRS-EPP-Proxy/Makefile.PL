
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "IETF EPP <=> SRS XML proxy software",
  "AUTHOR" => "Catalyst SRS Team <team-srs\@catalyst.net.nz>",
  "BUILD_REQUIRES" => {
    "XML::Compare" => "0.04"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "SRS-EPP-Proxy",
  "EXE_FILES" => [
    "bin/srs-epp-proxy"
  ],
  "LICENSE" => "perl",
  "NAME" => "SRS::EPP::Proxy",
  "PREREQ_PM" => {
    "Crypt::Password" => 0,
    "Event" => 0,
    "Log::Dispatch" => 0,
    "Module::Pluggable" => 0,
    "Moose" => "1.21",
    "MooseX::Daemonize" => 0,
    "MooseX::Getopt" => 0,
    "MooseX::Log::Log4perl" => 0,
    "MooseX::Params::Validate" => "0.16",
    "MooseX::SimpleConfig" => 0,
    "MooseX::Singleton" => "0.14",
    "XML::Assert" => "0.02",
    "XML::EPP" => "0.05",
    "XML::SRS" => "0.09"
  },
  "VERSION" => "0.22",
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



