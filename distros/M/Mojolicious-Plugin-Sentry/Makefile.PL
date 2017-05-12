

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Mojolicious::Plugin::Sentry',
	VERSION_FROM => 'lib/Mojolicious/Plugin/Sentry.pm', # finds \$VERSION
	AUTHOR       => 'Alexey Likhatskiy <likhatskiy\@gmail.com>',
	ABSTRACT     => 'A perl sentry client for Mojolicious',
	PREREQ_PM    => {
		'Test::Simple'  => 0.44,
		'Sentry::Raven' => 0,
		'Mojolicious'   => 0,
	},
);
