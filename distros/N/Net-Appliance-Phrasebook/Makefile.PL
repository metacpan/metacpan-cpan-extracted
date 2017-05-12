
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Network appliance command-line phrasebook',
  'AUTHOR' => 'Oliver Gorwits <oliver@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Net-Appliance-Phrasebook',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Net::Appliance::Phrasebook',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::Data::Inheritable' => '0',
    'Data::Phrasebook' => '0',
    'Data::Phrasebook::Loader::YAML' => '0',
    'File::Basename' => '0',
    'List::MoreUtils' => '0',
    'List::Util' => '0',
    'Symbol' => '0'
  },
  'VERSION' => '2.103642',
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



