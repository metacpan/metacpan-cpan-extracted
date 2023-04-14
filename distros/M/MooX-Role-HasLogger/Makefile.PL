#<<<
use strict; use warnings;
#>>>

use Config                        qw( %Config );
use ExtUtils::MakeMaker::CPANfile qw( WriteMakefile );

my %WriteMakefileArgs = (
  NAME             => 'MooX::Role::HasLogger',
  AUTHOR           => 'Sven Willenbuecher <sven.willenbuecher@gmx.de>',
  VERSION_FROM     => 'lib/MooX/Role/HasLogger.pm',
  ABSTRACT_FROM    => 'lib/MooX/Role/HasLogger.pod',
  LICENSE          => 'Perl_5',
  MIN_PERL_VERSION => '5.8.9',
  META_MERGE       => {
    'meta-spec' => { version => 2 },
    provides    => {
      'MooX::Role::HasLogger' => {
        file    => 'lib/MooX/Role/HasLogger.pm',
        version => '0.001002',
      },
      'MooX::Role::HasLogger::Types' => {
        file    => 'lib/MooX/Role/HasLogger/Types.pm',
        version => '0.001002',
      },
    },
    resources => {
      repository => {
        type => 'git',
        url  => 'git://github.com/XSven/MooX-Role-HasLogger.git',
        web  => 'https://github.com/XSven/MooX-Role-HasLogger',
      },
      bugtracker => {
        web => 'https://github.com/XSven/MooX-Role-HasLogger/issues',
      },
    },
  },
  clean     => { FILES    => 'MooX-Role-HasLogger-* cover_db' },
  dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  realclean => { FILES    => 'local' },
  test      => { RECURSIVE_TEST_FILES => 1 },
);

require './maint/AuthorExtensions.pl'
  unless ( $Config{ osname } =~ m/\A(?:freebsd|openbsd|solaris)\z/ or exists( $ENV{ MAKELEVEL } ) );

WriteMakefile( %WriteMakefileArgs );
