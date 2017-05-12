
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Testing framework for POE',
  'AUTHOR' => 'Sawyer X <xsawyerx@cpan.org>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'MooseX::POE' => '0',
    'POE' => '0',
    'POE::Kernel' => '0',
    'Test::Exception' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'POE-Test-Helpers',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'POE::Test::Helpers',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Data::Validate' => '0',
    'List::AllUtils' => '0',
    'Moose::Role' => '0',
    'POE::Session' => '0',
    'Test::Builder::Module' => '0',
    'Test::Deep' => '0',
    'Test::Deep::NoTest' => '0',
    'Test::More' => '0',
    'indirect' => '0',
    'namespace::autoclean' => '0',
    'parent' => '0',
    'strictures' => '1'
  },
  'VERSION' => '1.11',
  'test' => {
    'TESTS' => 't/*.t t/mooserole/*.t t/regular/*.t'
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



