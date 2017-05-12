
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "OO Interface for the REST services provided by Atlassian Bamboo",
  "AUTHOR" => "Mike Eldridge <diz\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Bamboo",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::Bamboo",
  "PREREQ_PM" => {
    "DateTimeX::Easy" => "0.089",
    "IO::File" => "0.14",
    "Moose" => "2.00",
    "MooseX::Types::URI" => "0.02",
    "XML::Tidy" => "1.12",
    "XML::XPath" => "1.13"
  },
  "VERSION" => "0.01",
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



