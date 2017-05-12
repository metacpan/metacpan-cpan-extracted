#!perl

use 5.010000;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME         => 'Music::Chord::Positions',
  VERSION_FROM => 'lib/Music/Chord/Positions.pm',
  PREREQ_PM    => {
    Carp                 => 0,
    'List::Util'         => 0,
    'Music::Chord::Note' => 0,    # nice to have, but not essential
    'Test::More'         => 0,
  },
  ( $] >= 5.005
    ? (
      ABSTRACT_FROM =>
        'lib/Music/Chord/Positions.pm',    # retrieve abstract from module
      AUTHOR => 'Jeremy Mates <jmates@cpan.org>'
      )
    : ()
  ),
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
  $params{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
  $params{META_MERGE} = {
    resources => {
      homepage   => 'http://github.com/thrig/Music-Chord-Positions',
      license    => 'http://dev.perl.org/licenses/',
      repository => 'http://github.com/thrig/Music-Chord-Positions',
    }
  };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.48' ) {
  $params{MIN_PERL_VERSION} = 5.010000;
}

WriteMakefile((MM->can('signature_target') ? (SIGN => 1) : ()), %params);
