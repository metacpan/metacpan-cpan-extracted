use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=> 'Mobile::Ads',
	'VERSION_FROM'		=> 'lib/Mobile/Ads.pm',
	'PREREQ_PM'	=> {
    		'LWP::UserAgent'			=> 0,
    		'HTTP::Request::Common'		=> 0,
    		'XML::LibXML'				=> 1.62,
	},
	'clean'		=> {
		'FILES'		=> 'Mobile-Ads-*'
	},
	'NO_META'		=> 1,
);
