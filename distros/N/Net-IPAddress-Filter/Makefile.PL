
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A compact and fast IP Address range filter",
  "AUTHOR" => "Dave Webb <Net-IPAddress-Filter\@d5ve.com>",
  "BUILD_REQUIRES" => {
    "English" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-IPAddress-Filter",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::IPAddress::Filter",
  "PREREQ_PM" => {
    "Net::CIDR::Lite" => 0,
    "Set::IntervalTree" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => 20140113,
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



