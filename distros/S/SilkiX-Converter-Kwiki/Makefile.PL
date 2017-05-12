
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Convert a Kwiki wiki to a Silki wiki',
  'AUTHOR' => 'Dave Rolsky <autarch@urth.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.88',
    'Test::Most' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'SilkiX-Converter-Kwiki',
  'EXE_FILES' => [
    'bin/kwiki2silki'
  ],
  'LICENSE' => 'artistic_2',
  'NAME' => 'SilkiX::Converter::Kwiki',
  'PREREQ_PM' => {
    'File::MimeInfo' => '0',
    'File::Slurp' => '0',
    'File::chdir' => '0',
    'HTML::Tidy' => '0',
    'JSON' => '0',
    'Kwiki' => '0',
    'Kwiki::Attachments' => '0',
    'Moose' => '0',
    'MooseX::Getopt' => '0',
    'MooseX::SemiAffordanceAccessor' => '0',
    'MooseX::StrictConstructor' => '0',
    'Path::Class' => '0',
    'Scalar::Util' => '0',
    'Silki' => '0.15',
    'URI::Escape' => '0',
    'namespace::autoclean' => '0'
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



