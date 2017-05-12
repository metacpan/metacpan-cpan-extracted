
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'provide regexes for U.S. profanity',
  'AUTHOR' => 'Terrence Brannon',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Regexp-Common-profanity_us',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Regexp::Common::profanity_us',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Data::Dumper' => '0',
    'Data::Section::Simple' => '0',
    'Exporter' => '0',
    'Regexp::Common' => '0'
  },
  'VERSION' => '4.112150',
  'test' => {
    'TESTS' => ''
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



