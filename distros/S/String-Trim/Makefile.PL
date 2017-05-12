
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'trim whitespace from your strings',
  'AUTHOR' => 'Mike Doherty <doherty@cpan.org>, Jeff Pinyan <pinyan@cpan.org>, Rob Kinyon <rkinyon@cpan.org>, Αριστοτέλης Παγκαλτζής (Aristotle Pagaltzis) <aristotle@cpan.org>',
  'BUILD_REQUIRES' => {
    'Data::Dumper' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::Builder' => '0.94',
    'Test::More' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'String-Trim',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'String::Trim',
  'PREREQ_PM' => {
    'Exporter' => '5.57'
  },
  'VERSION' => '0.005',
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



