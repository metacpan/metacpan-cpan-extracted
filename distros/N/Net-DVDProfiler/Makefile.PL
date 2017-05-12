use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		   => 'Net::DVDProfiler',
    'VERSION_FROM' => 'lib/Net/DVDProfiler.pm',
    'PREREQ_PM'    => {
		'LWP::Simple'      => 1.36
	}, 
    ($] >= 5.005 ? ( AUTHOR => 'John Resig <jeresig@gmail.com>') : ()),
);
