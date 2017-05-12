use ExtUtils::MakeMaker;

WriteMakefile(
    	NAME			=> 'PHP::Include',
    	VERSION_FROM		=> 'lib/PHP/Include.pm',
	PREREQ_PM		=> { 
				   'Parse::RecDescent'	=> 1,
				   'Filter::Simple'	=> .78 
				   },
     	ABSTRACT_FROM		=> 'lib/PHP/Include.pm', 
	AUTHOR			=> 'Alberto Simoes <ambs@cpan.org> and Ed Summers <ehs@pobox.com>',
);
