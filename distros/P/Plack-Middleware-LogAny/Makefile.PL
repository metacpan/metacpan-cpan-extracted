#<<<
use strict; use warnings;
#>>>

use ExtUtils::MakeMaker::CPANfile qw( WriteMakefile );

my %WriteMakefileArgs = (
  NAME          => 'Plack::Middleware::LogAny',
  AUTHOR        => 'Sven Willenbuecher <sven.willenbuecher@kuehne-nagel.com>',
  VERSION_FROM  => 'lib/Plack/Middleware/LogAny.pm',
  ABSTRACT_FROM => 'lib/Plack/Middleware/LogAny.pod',
  LICENSE       => 'Perl_5',
  META_MERGE    => {
    'meta-spec' => { version => 2 },
    resources   => {
      repository => {
        type => 'git',
        url  => 'git://github.com/XSven/Plack-Middleware-LogAny.git',
        web  => 'https://github.com/XSven/Plack-Middleware-LogAny',
      },
      bugtracker => {
        web => 'https://github.com/XSven/Plack-Middleware-LogAny/issues',
      },
    },
  },
  dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean     => { FILES    => 'Plack-Middleware-LogAny-* cover_db' },
  realclean => { FILES    => 'local' },
);

unless ( exists( $ENV{ MAKELEVEL } ) ) {
  my $local_lib = "$ENV{ PWD }/local/lib/perl5";
  require lib; lib->import( $local_lib );

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
