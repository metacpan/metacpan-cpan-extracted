use 5.001000;
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME              => 'Mojo::SMTP::Client',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/Mojo/SMTP/Client.pm', # finds $VERSION
	PREREQ_PM         => { 'Mojolicious' => 7.53 },
	BUILD_REQUIRES    => { 'Test::More' => 0.88 },
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => { 
		resources => {repository => 'https://github.com/olegwtf/p5-Mojo-SMTP-Client'},
	},
	ABSTRACT_FROM     => 'lib/Mojo/SMTP/Client.pm', # retrieve abstract from module
	AUTHOR            => 'Oleg G <oleg@cpan.org>'
);
