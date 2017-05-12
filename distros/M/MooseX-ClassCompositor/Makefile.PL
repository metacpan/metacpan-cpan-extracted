
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a factory that builds classes from roles",
  "AUTHOR" => "Ricardo Signes <rjbs\@cpan.org>, Mark Jason Dominus <mjd\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "MooseX-ClassCompositor",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "MooseX::ClassCompositor",
  "PREREQ_PM" => {
    "Class::Load" => 0,
    "Moose" => 0,
    "Moose::Util" => 0,
    "Moose::Util::MetaRole" => 0,
    "MooseX::StrictConstructor::Trait::Class" => 0,
    "MooseX::Types::Perl" => 0,
    "Scalar::Util" => 0,
    "String::RewritePrefix" => 0,
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "Data::OptList" => 0,
    "Moose::Role" => 0,
    "MooseX::Role::Parameterized" => "0.23",
    "Test::More" => "0.96",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.008",
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



