use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::PgAsync',
  VERSION_FROM => 'lib/Mojolicious/Plugin/PgAsync.pm',
  AUTHOR       => 'Alexander Romanenko <romanenko@cpan.org>',
  PREREQ_PM    => {
	  				'Mojolicious' => '0',
					'DBD::Pg' => '0',
				},
  test         => {TESTS => 't/*.t'}
);
