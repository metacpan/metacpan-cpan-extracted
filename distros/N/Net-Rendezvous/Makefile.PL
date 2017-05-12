use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'Net::Rendezvous',
	'VERSION_FROM' => 'lib/Net/Rendezvous.pm',
	'DISTNAME' => 'Net-Rendezvous',
	'PREREQ_PM' => { 'Net::DNS' => 0.44, 'Socket' => 1.75 },
	'AUTHOR' => 'George Chlipala <george@walnutcs.com>',
);
