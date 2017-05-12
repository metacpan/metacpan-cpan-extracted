
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "use Google's Picasa Web API",
  "AUTHOR" => "Andrew Sterling Hanenkamp <hanenkamp\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Google-PicasaWeb",
  "EXE_FILES" => [
    "bin/picasa",
    "bin/picasa-get",
    "bin/picasa-list",
    "bin/picasa",
    "bin/picasa-get",
    "bin/picasa-list"
  ],
  "LICENSE" => "perl",
  "NAME" => "Net::Google::PicasaWeb",
  "PREREQ_PM" => {
    "IO::Prompt" => 0,
    "LWP::Protocol::https" => 0,
    "LWP::UserAgent" => 0,
    "Moose" => 0,
    "MooseX::Role::Matcher" => 0,
    "Net::Google::AuthSub" => 0,
    "Test::Able" => "0.09",
    "Test::Able::Runner" => "1.000",
    "Test::Mock::LWP" => 0,
    "URI" => 0,
    "XML::Twig" => "3.30"
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.12",
  "test" => {
    "TESTS" => "t/*.t"
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



