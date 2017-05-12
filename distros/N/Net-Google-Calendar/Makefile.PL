
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Interface to Google calendars",
  "AUTHOR" => "Peter Lytle <pete\@bluecampaigns.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Google-Calendar",
  "EXE_FILES" => [
    "bin/google-calendar"
  ],
  "LICENSE" => "perl",
  "NAME" => "Net::Google::Calendar",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "Data::ICal" => 0,
    "Data::ICal::Entry::Event" => 0,
    "Date::ICal" => 0,
    "DateTime" => 0,
    "DateTime::Event::Recurrence" => 0,
    "DateTime::Format::ICal" => 0,
    "Encode" => 0,
    "HTTP::Cookies" => 0,
    "HTTP::Headers" => 0,
    "HTTP::Request" => 0,
    "HTTP::Request::Common" => 0,
    "LWP::Simple" => 0,
    "LWP::UserAgent" => 0,
    "Net::Google::AuthSub" => 0,
    "URI" => 0,
    "URI::Escape" => 0,
    "XML::Atom" => 0,
    "XML::Atom::Entry" => 0,
    "XML::Atom::Feed" => 0,
    "XML::Atom::Link" => 0,
    "XML::Atom::Person" => 0,
    "XML::Atom::Thing" => 0,
    "XML::Atom::Util" => 0,
    "base" => 0,
    "strict" => 0,
    "vars" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0,
    "lib" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.05",
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



