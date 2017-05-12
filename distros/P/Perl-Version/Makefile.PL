use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

my %ARGS = (
  license( 'perl' ),
  NAME          => 'Perl::Version',
  AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM  => 'lib/Perl/Version.pm',
  ABSTRACT_FROM => 'lib/Perl/Version.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
  	'Carp'               => 0,
    'Test::More'         => 0,
    'Scalar::Util'       => 0,
    'Getopt::Long'       => '2.34',
    'Pod::Usage'         => '1.3',
    'File::Slurp::Tiny'  => 0,
    'Data::Dumper'       => 0,
  },
  EXE_FILES => ['examples/perl-reversion'],
  dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Perl-Version-*' },
);

WriteMakefile( %ARGS );

sub license {
  my $lic = shift;
  local $^W = 0;    # Silence warning about non-numeric version
  return
   unless $ExtUtils::MakeMaker::VERSION >= '6.31';
  return ( LICENSE => $lic );
}
