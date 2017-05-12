
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Anonymous packages",
  "AUTHOR" => "Florian Ragwitz <rafl\@debian.org>, Ricardo Signes <rjbs\@cpan.org>, Jesse Luehrs <doy\@tozt.net>, Augustina Blair <auggy\@cpan.org>",
  "BUILD_REQUIRES" => {
    "FindBin" => 0,
    "Sub::Exporter" => 0,
    "Test::More" => 0,
    "overload" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Package-Anon",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Package::Anon",
  "PREREQ_PM" => {
    "Scalar::Util" => 0,
    "XSLoader" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.05",
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



