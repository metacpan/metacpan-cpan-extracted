
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "the ultimate configuration engine",
  "AUTHOR" => "Andrei Mishchenko <druxa\@yandex-team.ru>",
  "BUILD_REQUIRES" => {
    "Config" => 0,
    "Test::Class" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Morpheus",
  "EXE_FILES" => [
    "bin/morph"
  ],
  "LICENSE" => "perl",
  "NAME" => "Morpheus",
  "PREREQ_PM" => {
    "DBI" => 0,
    "Data::Dump" => 0,
    "Data::Dumper" => 0,
    "Digest::MD5" => 0,
    "Exporter" => 0,
    "File::Find" => 0,
    "Getopt::Long" => 0,
    "JSON" => 0,
    "Params::Validate" => 0,
    "Pod::Usage" => 0,
    "Symbol" => 0,
    "Template" => 0,
    "XML::Simple" => 0,
    "base" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.46",
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



