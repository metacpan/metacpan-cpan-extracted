
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "The DataFlow Module Collection (new flavor)",
  "AUTHOR" => "Alexei Znamensky <russoz\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-DataFlow",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Task::DataFlow",
  "PREREQ_PM" => {
    "DataFlow" => "1.121690",
    "DataFlow::Proc::DBF" => 0,
    "DataFlow::Proc::DPath" => "1.112100",
    "DataFlow::Proc::HTMLFilter" => "1.112100",
    "DataFlow::Proc::JSON" => "1.112100",
    "DataFlow::Proc::MessagePack" => "1.112100",
    "DataFlow::Proc::URLRetriever" => "1.112100",
    "DataFlow::Proc::YAML" => "1.112100",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.008",
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



