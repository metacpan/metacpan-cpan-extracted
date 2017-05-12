
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Library for things around the prosody XMPP server",
  "AUTHOR" => "Torsten Raudssus <torsten\@raudssus.de> L<http://www.raudssus.de/>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.96",
    "Test::Simple" => "0.98"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Prosody",
  "EXE_FILES" => [
    "bin/copy_prosody_db"
  ],
  "LICENSE" => "perl",
  "NAME" => "Prosody",
  "PREREQ_PM" => {
    "DBIx::Class" => "0.08192",
    "DBIx::Class::Candy" => "0.002000",
    "Encode" => "2.44",
    "HTTP::Request" => 0,
    "JSON" => "2.53",
    "LWP::UserAgent" => 0,
    "Moose" => "2.0007",
    "MooseX::Getopt" => 0
  },
  "VERSION" => "0.007",
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



