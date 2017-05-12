
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "FastCGI Server",
  "AUTHOR" => "\303\201rp\303\241d Sz\303\241sz <arpad.szasz\@plenum.ro>",
  "BUILD_REQUIRES" => {
    "File::Slurp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Mojo-Server-FastCGI",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Mojo::Server::FastCGI",
  "PREREQ_PM" => {
    "Mojolicious" => "3.21"
  },
  "VERSION" => "0.41",
  "test" => {
    "TESTS" => "t/mojo/*.t"
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



