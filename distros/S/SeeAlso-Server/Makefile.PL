
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "SeeAlso Linkserver Protocol Server",
  "AUTHOR" => "Jakob Voss",
  "BUILD_REQUIRES" => {
    "CHI" => 0,
    "Cache::Memory" => 0,
    "Data::Dumper" => 0,
    "File::Temp" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "SeeAlso-Server",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "SeeAlso::Server",
  "PREREQ_PM" => {
    "Business::ISBN" => 0,
    "CGI" => 0,
    "Carp" => 0,
    "Config::IniFiles" => 0,
    "DBI" => 0,
    "DBI::Const::GetInfoType" => 0,
    "Data::Validate::URI" => 0,
    "Date::Parse" => 0,
    "Exporter" => 0,
    "JSON::XS" => 0,
    "LWP::Simple" => 0,
    "POSIX" => 0,
    "Text::CSV" => 0,
    "URI" => 0,
    "YAML::Any" => 0,
    "base" => 0,
    "overload" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.71",
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



