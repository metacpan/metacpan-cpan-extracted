use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'SVG::SpriteMaker',
	VERSION_FROM      => 'lib/SVG/SpriteMaker.pm',
	ABSTRACT_FROM     => 'lib/SVG/SpriteMaker.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	EXE_FILES         => ['svg-spritemaker'],
	MIN_PERL_VERSION  => 5.014000,
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/SVG         0
		   SVG::Parser 0/,
	},
	META_MERGE         => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=svg-spritemaker.git'
		},
	}
);
