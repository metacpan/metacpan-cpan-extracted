
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "LDAP filter to SQL clause transformer",
  "AUTHOR" => "Tim Esselens <tim.esselens\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-LDAP-Filter-SQL",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::LDAP::Filter::SQL",
  "PREREQ_PM" => {
    "Net::LDAP::Filter" => 0,
    "Test::Deep" => 0,
    "Test::Most" => 0,
    "parent" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.03",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Net::LDAP::Filter" => 0,
  "Test::Deep" => 0,
  "Test::Most" => 0,
  "parent" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



