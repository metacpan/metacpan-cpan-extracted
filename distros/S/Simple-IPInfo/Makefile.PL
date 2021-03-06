# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.009.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Get IP/IPList Info (location, as number, etc)\r",
  "AUTHOR" => "Abby Pan <abbypan\@gmail.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Simple-IPInfo",
  "EXE_FILES" => [
    "bin/add_inet.pl",
    "bin/add_ip_info.pl",
    "bin/get_ipinfo.pl",
    "bin/make_inet_from_cidr.pl",
    "bin/merge_inet.pl",
    "bin/refine_inet.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Simple::IPInfo",
  "PREREQ_PM" => {
    "Data::Validate::IP" => 0,
    "JSON" => 0,
    "Memoize" => 0,
    "Net::CIDR" => 0,
    "SimpleR::Reshape" => 0
  },
  "VERSION" => "0.12",
  "test" => {
    "TESTS" => ""
  }
);


my %FallbackPrereqs = (
  "Data::Validate::IP" => 0,
  "JSON" => 0,
  "Memoize" => 0,
  "Net::CIDR" => 0,
  "SimpleR::Reshape" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
