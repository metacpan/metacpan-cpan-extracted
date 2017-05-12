# $Id: Makefile.PL 201 2009-07-28 06:39:31Z rcaputo $

use ExtUtils::MakeMaker;

# Touch auto-generated files so we don't see warnings.
open(CHANGES, ">>CHANGES") and close CHANGES;
open(README, ">>README")   and close README;

WriteMakefile(
  NAME         => 'POE::Stage',
  AUTHOR       => 'Rocco Caputo <rcaputo@cpan.org>',
  ABSTRACT     => 'a prototype of a successor to POE::Component',
  LICENSE      => 'perl',
  VERSION_FROM => 'lib/POE/Stage.pm',
  PREREQ_PM    => {
    'Attribute::Handlers'   => 0.78,
    'Net::DNS'              => 0.53,
    'PadWalker'             => 1.0,
    'Scalar::Util'          => 1.18,
    'POE'                   => 1.007,
    'Test::More'            => 0,
    'Devel::LexAlias'       => 0.04,
		'Lexical::Persistence'  => 0.95, # Currently unused.
		'Hash::Util::FieldHash' => 1.03,
  },
  META_ADD     => {
    resources  => {
      license    => 'http://dev.perl.org/licenses/',
      repository => 'http://thirdlobe.com/svn/poe-stage/trunk'
    },
  },
  dist         => {
    COMPRESS   => 'gzip -9f',
    SUFFIX     => 'gz',
    PREOP      => (
      'svn-log.perl | tee ./$(DISTNAME)-$(VERSION)/CHANGES > ./CHANGES;' .
      'LANG=C perldoc lib/POE/Stage.pm > README'
    ),
  },
);
