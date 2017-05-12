
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Disqus.com API access',
  'AUTHOR' => 'Ben van Staveren <madcat@cpan.org>',
  'BUILD_REQUIRES' => {
    'Module::Build' => '0.38',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.38'
  },
  'DISTNAME' => 'Net-Disqus',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Net::Disqus',
  'PREREQ_PM' => {
    'Class::Accessor' => '0',
    'JSON::PP' => '0',
    'LWP::UserAgent' => '0',
    'Try::Tiny' => '0',
    'URI' => '0',
    'URI::Escape' => '0',
    'overload' => '0'
  },
  'VERSION' => '1.19',
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



