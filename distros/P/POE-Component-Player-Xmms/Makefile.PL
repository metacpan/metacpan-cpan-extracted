use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME			=> 'POE::Component::Player::Xmms',
	AUTHOR          => 'David Davis <xantus@cpan.org>',
    ABSTRACT        => 'Non-blocking POE interface to Xmms music player',
	VERSION_FROM	=> 'Xmms.pm',
	AUTHOR			=> 'David Davis <xantus@cpan.org>',
	PREREQ_PM		=> {
        POE => 0.32,
	    Xmms => 0.12,
    },
);
