
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Brings in all Perl modules which are RPM packaged and shipped with B<cPanel & WHM> and B<EasyApache>.",
  "AUTHOR" => "cPanel <cpanel\@cpan.org>",
  "BUILD_REQUIRES" => {
    "FindBin" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-Cpanel",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Task::Cpanel",
  "PREREQ_PM" => {
    "Task::Cpanel::3rdparty" => 0,
    "Task::Cpanel::Catalyst" => 0,
    "Task::Cpanel::Core" => 0,
    "Task::Cpanel::Internal" => 0,
    "Task::Cpanel::Kensho" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "11.36.001",
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



