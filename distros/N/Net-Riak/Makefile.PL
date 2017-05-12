
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Interface to Riak",
  "AUTHOR" => "franck cuny <franck\@lumberjaph.net>, robin edwards <robin.ge\@gmail.com>",
  "BUILD_REQUIRES" => {
    "HTTP::Response" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Riak",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::Riak",
  "PREREQ_PM" => {
    "Data::Dump" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "Google::ProtocolBuffers" => 0,
    "IO::Socket::INET" => 0,
    "IO::Socket::SSL" => 0,
    "JSON" => 0,
    "LWP::ConnCache" => 0,
    "LWP::UserAgent" => 0,
    "List::Util" => 0,
    "MIME::Base64" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::Role::Parameterized" => 0,
    "MooseX::Traits" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Structured" => 0,
    "Scalar::Util" => 0,
    "URI" => 0,
    "base" => 0,
    "bytes" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.1702",
  "test" => {
    "TESTS" => "t/*.t t/pbc/*.t t/rest/*.t"
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



