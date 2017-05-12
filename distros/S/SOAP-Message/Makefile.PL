use ExtUtils::MakeMaker;

&WriteMakefile(

	NAME              => 'SOAP::Message',
	VERSION_FROM      => 'lib/SOAP/Message.pm',
	PREREQ_PM         => {

		'Test::More' => '0.01',
		'XML::XPath' => '0.01',

	}, 

);
