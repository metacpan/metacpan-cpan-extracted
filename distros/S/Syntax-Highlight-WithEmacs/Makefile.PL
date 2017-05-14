
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "syntax-highlight source code using Emacs",
  "AUTHOR" => "Ailin Nemui <ailin at devio dot us>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Syntax-Highlight-WithEmacs",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Syntax::Highlight::WithEmacs",
  "PREREQ_PM" => {
    "CSS::Tiny" => 0,
    "Carp" => 0,
    "File::Temp" => 0,
    "Hash::Util" => 0,
    "IPC::Run" => 0,
    "Moops" => 0,
    "Term::ANSIColor" => 0,
    "XML::LibXML" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Cwd" => 0,
    "Devel::Hide" => 0,
    "Test::More" => 0,
    "Test::Most" => 0,
    "ok" => 0,
    "strict" => 0
  },
  "VERSION" => "0.2",
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



