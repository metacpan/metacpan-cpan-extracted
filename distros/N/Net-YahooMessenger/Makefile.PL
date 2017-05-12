use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Net::YahooMessenger',
    'VERSION_FROM'	=> 'lib/Net/YahooMessenger.pm',
    'PREREQ_PM'		=> {
		'Digest::MD5' => 0.0,
		'WWW::Mechanize' => 0.0,
        'MD5' => 0.0,
	},
);
