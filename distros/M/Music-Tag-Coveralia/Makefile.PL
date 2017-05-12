use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Music::Tag::Coveralia',
	VERSION_FROM      => 'lib/Music/Tag/Coveralia.pm',
	ABSTRACT_FROM     => 'lib/Music/Tag/Coveralia.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	BUILD_REQUIRES    => {
		qw/Test::RequiresInternet 0/,
	},
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Music::Tag 0
		   Music::Tag::Generic 0
		   WWW::Search 0
		   WWW::Search::Coveralia 0/,
	},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=music-tag-coveralia.git',
		},
	}
);
