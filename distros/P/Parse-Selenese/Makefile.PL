
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Parser for Selenese",
  "AUTHOR" => "Theodore Robert Campbell Jr <trcjr\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Algorithm::Diff" => 0,
    "Data::Dumper" => 0,
    "File::Find" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "Path::Class" => 0,
    "Test::Class::Load" => 0,
    "Test::Class::Most" => 0,
    "Test::Differences" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Test::Most" => 0,
    "Test::WWW::Selenium" => 0,
    "Time::HiRes" => 0,
    "YAML" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Parse-Selenese",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Parse::Selenese",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Cwd" => 0,
    "Encode" => 0,
    "File::Basename" => 0,
    "File::Temp" => 0,
    "HTML::Element" => 0,
    "HTML::TreeBuilder" => 0,
    "Moose" => 0,
    "MooseX::AttributeShortcuts" => 0,
    "Template" => 0,
    "Text::MicroTemplate" => 0,
    "Try::Tiny" => 0,
    "open" => 0
  },
  "VERSION" => "0.006",
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



