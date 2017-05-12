use 5.006000;
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME              => 'Mojo::Email::Checker::SMTP',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/Mojo/Email/Checker/SMTP.pm',
	PREREQ_PM         => { 
		'Mojolicious' => 5, # Delay->catch()
		'Net::DNS'    => 0.66, # Fix for bgsend
	},
	BUILD_REQUIRES    => {
		#'Test::More' => 0.88
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => { 
		resources => {repository => 'https://github.com/Snelius30/Mojo-Email-Checker-SMTP'},
	},
	($] >= 5.005 ?
	(ABSTRACT_FROM  => 'lib/Mojo/Email/Checker/SMTP.pm',
	AUTHOR         => 'Anatoly Y. <snelius@cpan.org>') : ()),
);
