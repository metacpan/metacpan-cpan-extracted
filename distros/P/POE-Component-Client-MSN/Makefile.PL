use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'POE::Component::Client::MSN',
    'VERSION_FROM' => 'lib/POE/Component/Client/MSN.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'POE'        => 0.29,
	'Digest::MD5' => 2.20,
    },
);
