
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "An SMTP client supporting TLS and AUTH (DEPRECATED, use Net::SMTPS instead)",
  "AUTHOR" => "Alexander Christian Westholm <awestholm at verizon dawt net>, Fayland Lam <fayland\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-SMTP-TLS-ButMaintained",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::SMTP::TLS::ButMaintained",
  "PREREQ_PM" => {
    "Digest::HMAC_MD5" => 0,
    "IO::Socket::INET" => 0,
    "IO::Socket::SSL" => "1.76",
    "MIME::Base64" => 0,
    "Net::Cmd" => 0,
    "Net::SSLeay" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.24",
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



