
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Params::Validate checks for functions taking integer arguments',
  'AUTHOR' => 'Stephen Cardie <stephenca@cpan.org>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'File::Spec' => '0',
    'Test::More' => '0',
    'Test::Most' => '0.23',
    'Test::Perl::Critic' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Params-Validate-Checks-Integer',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'Params::Validate::Checks::Integer',
  'PREREQ_PM' => {
    'Params::Validate' => '0.95',
    'Params::Validate::Checks' => '0.01',
    'Scalar::Util::Numeric' => '0.22'
  },
  'VERSION' => '0.01',
  'test' => {
    'TESTS' => 't/*.t t/lib/params/validate/checks/*.t'
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



