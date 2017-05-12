#!perl

use 5.006000;

use strict;
use warnings;
use ExtUtils::MakeMaker;

# due to cpantesters failures from Win32 smoke machines
if ( $^O =~ m/MSWin32/ ) {
  print "Sorry, no automated install on Windows due to lack of POSIX::tcgetpgrp.\n";
  exit(0);
}

my %params = (
  NAME         => 'Term::CallEditor',
  ABSTRACT     => 'solicit data from an external editor',
  VERSION_FROM => 'lib/Term/CallEditor.pm',
  PREREQ_PM    => {
    'File::Temp' => 0.18,
    'IO::Handle' => 0,
    'Test::More' => 0.72,
  },
  ( $] >= 5.005
    ? ( AUTHOR => 'Jeremy Mates <jmates@cpan.org>' )
    : ()
  ),
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
  $params{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
  $params{META_MERGE} = {
    resources => {
      homepage   => 'http://github.com/thrig/Term-CallEditor',
      license    => 'http://dev.perl.org/licenses/',
      repository => 'http://github.com/thrig/Term-CallEditor',
    }
  };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.48' ) {
  $params{MIN_PERL_VERSION} = 5.006000;
}

WriteMakefile((MM->can('signature_target') ? (SIGN => 1) : ()), %params);
