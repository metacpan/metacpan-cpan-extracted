use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Ogg::Vorbis::Header::PurePerl',
	'VERSION_FROM'	=> 'PurePerl.pm',
	'PREREQ_PM'		=> {},
	($] >= 5.005 ?
	(ABSTRACT_FROM => 'PurePerl.pm',
	AUTHOR     => 'Dan Sully <daniel@cpan.org>') : ()),
);
