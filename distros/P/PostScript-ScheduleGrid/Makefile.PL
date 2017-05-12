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

You cannot use PostScript::ScheduleGrid with MooseX::Types 0.32 or greater
unless your Moose is 2.0800 or greater.  Either upgrade Moose or
downgrade MooseX::Types to 0.31 or below.
END ERROR
    exit 0;
  }
};

my %WriteMakefileArgs = (
  NAME => "PostScript::ScheduleGrid",
  VERSION_FROM => "lib/PostScript/ScheduleGrid.pm",
  'ABSTRACT' => 'Print a schedule in a grid format',
  'AUTHOR' => 'Christopher J. Madsen <perl@cjmweb.net>',
  'LICENSE' => 'perl',
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30',
    'Moose' => '0',
    'MooseX::Types' => '0',
    'version' => '0.77'
  },
  'PREREQ_PM' => {
    'DateTime' => '0',
    'DateTime::TimeZone' => '0',
    'List::Util' => '1.20',
    'Module::Runtime' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::DateTime' => '0',
    'MooseX::Types::Moose' => '0',
    'POSIX' => '0',
    'PostScript::File' => '2.20',
    'namespace::autoclean' => '0'
  },
  'TEST_REQUIRES' => {
    'Data::Dumper' => '0',
    'Encode' => '0',
    'Test::More' => '0.88'
  },
  "test" => {
    "TESTS" => "t/*.t"
  }
);

if (my $tr = delete $WriteMakefileArgs{TEST_REQUIRES} and
    not eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $br = $WriteMakefileArgs{BUILD_REQUIRES} ||= {};
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
