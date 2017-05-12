
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Minimal-configuration, read-only LDAP server",
  "AUTHOR" => "Alexei Znamensky <russoz\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Authen::SASL" => 0,
    "Exporter" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "IO::Pipe" => 0,
    "Net::LDAP" => 0,
    "Proc::Fork" => 0,
    "Test::More" => "0.88",
    "Test::UseAllModules" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-LDAP-SimpleServer",
  "EXE_FILES" => [
    "bin/ldapd.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Net::LDAP::SimpleServer",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "File::Basename" => 0,
    "File::HomeDir" => 0,
    "File::Path" => "2.08",
    "File::Spec" => 0,
    "Net::LDAP::Constant" => 0,
    "Net::LDAP::FilterMatch" => 0,
    "Net::LDAP::LDIF" => 0,
    "Net::LDAP::Server" => 0,
    "Net::LDAP::Util" => 0,
    "Net::Server" => "2.003",
    "Scalar::Util" => 0,
    "UNIVERSAL::isa" => 0,
    "base" => 0,
    "fields" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.0.17",
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



