
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A fully event-driven networkable IRC server daemon module.",
  "AUTHOR" => "Chris Williams <chris\@bingosnet.co.uk>, Hinrik \303\226rn Sigur\303\260sson <hinrik.sig\@gmail.com>",
  "BUILD_REQUIRES" => {
    "POE::Component::IRC" => "6.68",
    "Test::More" => "0.47"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "POE-Component-Server-IRC",
  "EXE_FILES" => [
    "bin/pmkpasswd"
  ],
  "LICENSE" => "perl",
  "NAME" => "POE::Component::Server::IRC",
  "PREREQ_PM" => {
    "Crypt::PasswdMD5" => "1.3",
    "IRC::Utils" => "0.10",
    "List::Util" => 0,
    "Net::Netmask" => "1.9012",
    "POE" => "0.9999",
    "POE::Component::Client::DNS" => "1.00",
    "POE::Component::Client::Ident" => "1.00",
    "POE::Component::Syndicator" => "0.04",
    "POE::Filter::IRCD" => "2.2"
  },
  "VERSION" => "1.54",
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



