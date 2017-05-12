
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Enable template toolkit to use Amazon's S3 service as a provier of templates.",
  "AUTHOR" => "Gautam Dey <gdey\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Digest::SHA1" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Template-Provider-Amazon-S3",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Template::Provider::Amazon::S3",
  "PREREQ_PM" => {
    "CHI" => "0.50",
    "Data::Dumper" => 0,
    "DateTime" => 0,
    "JSON" => 0,
    "List::MoreUtils" => 0,
    "Net::Amazon::S3::Client" => 0,
    "Template::Provider" => 0,
    "Try::Tiny" => 0,
    "base" => 0,
    "feature" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.009",
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



