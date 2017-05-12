use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'POE::Component::YahooMessenger',
    'VERSION_FROM' => 'lib/POE/Component/YahooMessenger.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'Net::YahooMessenger' => 0.13,
	'POE' => 0.22,
    },
);
