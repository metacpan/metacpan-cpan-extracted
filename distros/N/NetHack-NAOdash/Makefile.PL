use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'NetHack::NAOdash',
	VERSION_FROM     => 'lib/NetHack/NAOdash.pm',
	ABSTRACT_FROM    => 'lib/NetHack/NAOdash.pm',
	AUTHOR           => 'Marius Gavrilescu <marius@ieval.ro>',
	EXE_FILES        => ['naodash'],
	MIN_PERL_VERSION => '5.14.0',
	LICENSE          => 'perl',
	SIGN             => 1,
	PREREQ_PM        => {
		qw/File::Slurp       0
		   HTML::TreeBuilder 0
		   JSON::MaybeXS     0
		   List::MoreUtils   0
		   Plack::Component  0
		   Term::ANSIColor   0
		   Text::XLogfile    0/,
	},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=nethack-naodash.git',
		},
	}
);
