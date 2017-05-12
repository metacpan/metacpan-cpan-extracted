use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=> 'Mobile::Messagin::ParlayX',
	'VERSION_FROM'		=> 'lib/Mobile/Messaging/ParlayX.pm',
	'PREREQ_PM'	=> {
    		'LWP::UserAgent'	=> 0,
    		'HTTP::Request'		=> 0,
    		'XML::LibXML'		=> 1.62,
	},
	'clean'		=> {
		'FILES'		=> 'Mobile-Messaging-ParlayX-*'
	},
	'NO_META'		=> 1,
);
