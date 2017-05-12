#!perl

use 5.010000;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME         => 'Music::Scala',
  VERSION_FROM => 'lib/Music/Scala.pm',
  ABSTRACT     => 'Scala scale support for Perl',
  PREREQ_PM    => {
    Carp               => 0,
    'File::Basename'   => 0,
    'Moo'              => 0,
    'namespace::clean' => 0,
    'Scalar::Util'     => 0,
    'Test::Exception'  => 0,
    'Test::More'       => 0,
  },
  ( $] >= 5.005
    ? ( AUTHOR => 'Jeremy Mates <jmates@cpan.org>' )
    : ()
  ),
  # For File::Cmp related test code. Input scala are all under the root dir, so
  # for tests must write to an alternate directory, as the convention is to
  # include the file basename inside the file...
  clean => { FILES => 't/*.scl' },
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
  $params{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
  $params{META_MERGE} = {
    resources => {
      homepage   => 'http://github.com/thrig/Music-Scala',
      license    => 'http://dev.perl.org/licenses/',
      repository => 'http://github.com/thrig/Music-Scala',
    }
  };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.48' ) {
  $params{MIN_PERL_VERSION} = 5.010000;
}

WriteMakefile( ( MM->can('signature_target') ? ( SIGN => 1 ) : () ), %params );
