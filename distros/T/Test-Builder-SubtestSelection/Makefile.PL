#<<<
use strict; use warnings;
#>>>

use Config                        qw( %Config );
use ExtUtils::MakeMaker::CPANfile qw( WriteMakefile );

my %WriteMakefileArgs = (
  NAME             => 'Test::Builder::SubtestSelection',
  AUTHOR           => 'Sven Willenbuecher <sven.willenbuecher@gmx.de>',
  VERSION_FROM     => 'lib/Test/Builder/SubtestSelection.pm',
  ABSTRACT_FROM    => 'lib/Test/Builder/SubtestSelection.pod',
  LICENSE          => 'Perl_5',
  MIN_PERL_VERSION => '5.6.2',
  META_MERGE       => {
    'meta-spec' => { version => 2 },
    provides    => {
      'Test::Builder::SubtestSelection' => {
        file    => 'lib/Test/Builder/SubtestSelection.pm',
        version => '0.001003',
      },
    },
    resources => {
      repository => {
        type => 'git',
        url  => 'git://github.com/XSven/Test-Builder-SubtestSelection.git',
        web  => 'https://github.com/XSven/Test-Builder-SubtestSelection',
      },
      bugtracker => {
        web => 'https://github.com/XSven/Test-Builder-SubtestSelection/issues',
      },
    },
  },
  clean     => { FILES    => 'Test-Builder-SubtestSelection-* cover_db' },
  dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  realclean => { FILES    => 'local' },
  test      => { RECURSIVE_TEST_FILES => 1 },
);

require './maint/AuthorExtensions.pl'
  unless ( $Config{ osname } =~ m/\A(?:freebsd|openbsd|solaris)\z/ or exists( $ENV{ MAKELEVEL } ) );

WriteMakefile( %WriteMakefileArgs );
