use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'POE::Wheel::Audio::Mad',
    'VERSION_FROM'	=> 'Mad.pm',
    
    'PREREQ_PM'		=> { 
    	Audio::Mad => 0.5,
    	Audio::OSS => 0.0501
    },
    
    ($] >= 5.005 ? (
    	ABSTRACT_FROM => 'Mad.pm',
    	AUTHOR        => 'Mark McConnell <mischke@cpan.org>'
    ) : ()),
);
