use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;
use version 0.77;

eval {
  require Moose;
  require MooseX::Types;

  my $Moose   = Moose->VERSION;
  my $MooseXT = MooseX::Types->VERSION;

  if ((version->parse($Moose)   < version->parse('2.0800')) and
      (version->parse($MooseXT) > version->parse('0.31'))) {
    print <<"END ERROR";

ERROR: Found Moose $Moose with MooseX::Types $MooseXT

You cannot use PostScript::Report with MooseX::Types 0.32 or greater
unless your Moose is 2.0800 or greater.  Either upgrade Moose or
downgrade MooseX::Types to 0.31 or below.
END ERROR
    exit 0;
  }
};

my %WriteMakefileArgs = (
  NAME => "PostScript::Report",
  VERSION_FROM => "lib/PostScript/Report.pm",
  'ABSTRACT' => 'Produce formatted reports in PostScript',
  'AUTHOR' => 'Christopher J. Madsen <perl@cjmweb.net>',
  'LICENSE' => 'perl',
  'BUILD_REQUIRES' => {
    'Encode' => '0',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30',
    'Moose' => '0',
    'MooseX::Types' => '0',
    'version' => '0.77'
  },
  'PREREQ_PM' => {
    'Carp' => '0',
    'File::Spec' => '0',
    'List::Util' => '0',
    'Module::Runtime' => '0',
    'Moose' => '0.90',
    'Moose::Role' => '0',
    'MooseX::AttributeTree' => '0.02',
    'MooseX::Types' => '0',
    'MooseX::Types::Moose' => '0',
    'PostScript::File' => '2.20',
    'Scalar::Util' => '0',
    'String::RewritePrefix' => '0',
    'namespace::autoclean' => '0'
  },
  "test" => {
    "TESTS" => "t/*.t"
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
