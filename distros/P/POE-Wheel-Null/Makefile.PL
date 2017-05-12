use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'POE::Wheel::Null',
	VERSION_FROM	=> 'lib/POE/Wheel/Null.pm',
	PREREQ_PM	=> {
		POE => 0,
    	},
	($] >= 5.005
		? (
			ABSTRACT_FROM  => 'lib/POE/Wheel/Null.pm',
			AUTHOR         => 'Jonathan Steinert <hachi@cpan.org>',
		)
		: ()
	),
	dist => {
		COMPRESS => 'gzip -9',
		SUFFIX   => 'gz',
		PREOP    => q{pod2text lib/POE/Wheel/Null.pm > ./$(DISTNAME)-$(VERSION)/README},
	},		      
);
