
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'a class that delegates an interface to a set of objects that do that interface',
  'AUTHOR' => 'Jonathan Rockway <jrockway@cpan.org>',
  'BUILD_REQUIRES' => {
    'MooseX::APIRole' => '0',
    'Scalar::Util' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'MooseX-MultiObject',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'MooseX::MultiObject',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::MOP::Method::Generated' => '0',
    'Moose' => '0',
    'Moose::Exporter' => '0',
    'Moose::Meta::Method' => '0',
    'Moose::Meta::TypeConstraint::Class' => '0',
    'Moose::Meta::TypeConstraint::Role' => '0',
    'Moose::Role' => '0',
    'Moose::Util' => '0',
    'MooseX::APIRole::Internals' => '0',
    'MooseX::Types::Set::Object' => '0',
    'Set::Object' => '0',
    'namespace::autoclean' => '0',
    'parent' => '0',
    'true' => '0'
  },
  'VERSION' => '0.03',
  'test' => {
    'TESTS' => 't/*.t'
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



