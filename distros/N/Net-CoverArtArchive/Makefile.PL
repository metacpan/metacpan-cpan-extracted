
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Query the coverartarchive.org",
  "AUTHOR" => "Oliver Charles <oliver\@musicbrainz.org>, Brian Cassidy <bricas\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find::Rule" => "0.33",
    "Test::More" => "0.90",
    "Try::Tiny" => "0.11"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-CoverArtArchive",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::CoverArtArchive",
  "PREREQ_PM" => {
    "JSON::Any" => "1.29",
    "LWP::UserAgent" => "6.03",
    "Moose" => "2.0402",
    "namespace::autoclean" => "0.13"
  },
  "VERSION" => "1.02",
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



