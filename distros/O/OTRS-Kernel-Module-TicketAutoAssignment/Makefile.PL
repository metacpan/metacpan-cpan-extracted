
use strict;
use warnings;

use 5.008007;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Customize TicketAutoAssignment from GUI Interface.",
  "AUTHOR" => "Basu Rohit <rohitbasu\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Kernel-Modules-TicketAutoAssignment",
  "EXE_FILES" => [
    "bin/otrs.AutoAllocation.pl"
  ],
  "LICENSE" => "open_source",
  "NAME" => "Kernel::Modules::TicketAutoAssignment",
  "PREREQ_PM" => {
    "Encode" => 0,
    "Encode::Locale" => 0,
    "Getopt::Long" => 0,
    "Pod::Usage" => 0,
    "SOAP::Lite" => 0
  },
  "VERSION" => "1.0.1",
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



