use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		   => 'Net::Amazon::DVD2IMDB',
    'VERSION_FROM' => 'lib/Net/Amazon/DVD2IMDB.pm',
    'PREREQ_PM'    => {
		'Test::More'       => 0.47,
		'LWP::Simple'      => 1.36,
		'Net::Amazon' 	=> 0.18
	}, 
    ($] >= 5.005 ? ( AUTHOR => 'John Resig <jeresig@gmail.com>') : ()),
);
