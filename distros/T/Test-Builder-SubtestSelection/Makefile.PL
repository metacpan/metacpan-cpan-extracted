#<<<
use strict; use warnings;
#>>>

use Config                        qw( %Config );
use ExtUtils::MakeMaker::CPANfile qw( WriteMakefile );

my %WriteMakefileArgs = (
  NAME             => 'Test::Builder::SubtestSelection',
  AUTHOR           => 'Sven Willenbuecher <sven.willenbuecher@kuehne-nagel.com>',
  VERSION_FROM     => 'lib/Test/Builder/SubtestSelection.pm',
  ABSTRACT_FROM    => 'lib/Test/Builder/SubtestSelection.pod',
  LICENSE          => 'Perl_5',
  MIN_PERL_VERSION => '5.6.2',
  META_MERGE       => {
    'meta-spec' => { version => 2 },
    provides    => {
      'Test::Builder::SubtestSelection' => {
        file    => 'lib/Test/Builder/SubtestSelection.pm',
        version => '0.001002',
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
  dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean     => { FILES    => 'Test-Builder-SubtestSelection-* cover_db' },
  realclean => { FILES    => 'local' },
);

unless ( $Config{ osname } =~ m/\A(?:freebsd|openbsd|solaris)\z/ or exists( $ENV{ MAKELEVEL } ) ) {
  my $local_lib = "$ENV{ PWD }/local/lib/perl5";
  require lib;
  lib->import( $local_lib );

  no warnings 'once';
  *MY::postamble = sub {
    my $make_fragment .= <<"MAKE_FRAGMENT";
ifdef PERL5LIB
  PERL5LIB := $local_lib:\$(PERL5LIB)
else
  export PERL5LIB := $local_lib
endif

.PHONY: installdeps
installdeps: cpanfile
	cpanm --no-man-pages --local-lib-contained $local_lib/../.. --installdeps .

.PHONY: cover
cover:
	cover -test -ignore local -report vim
MAKE_FRAGMENT

    return $make_fragment;
  }
}

WriteMakefile( %WriteMakefileArgs );
