
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "SPORE client",
  "AUTHOR" => "franck cuny <franck\@lumberjaph.net>, Ash Berlin <ash\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-HTTP-Spore",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::HTTP::Spore",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Digest::SHA" => 0,
    "HTTP::Headers" => 0,
    "HTTP::Request" => 0,
    "IO::All" => 0,
    "IO::File" => 0,
    "JSON" => 0,
    "LWP::UserAgent" => 0,
    "MIME::Base64" => 0,
    "Moose" => 0,
    "Moose::Exporter" => 0,
    "Moose::Meta::Method" => 0,
    "Moose::Role" => 0,
    "Moose::Util::MetaRole" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Role::Parameterized" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::URI" => 0,
    "Scalar::Util" => 0,
    "Time::HiRes" => 0,
    "Try::Tiny" => 0,
    "URI" => 0,
    "URI::Escape" => 0,
    "XML::Simple" => 0,
    "YAML" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Temp" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "base" => 0
  },
  "VERSION" => "0.06",
  "test" => {
    "TESTS" => "t/*.t t/spore-method/*.t t/spore-middleware/*.t t/spore-request/*.t t/spore-response/*.t t/spore-role/*.t t/spore/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



