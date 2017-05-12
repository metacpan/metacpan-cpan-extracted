use ExtUtils::MakeMaker;

my $VERSION = '1.9';

my $ABSTRACT = "Please use SOAP::XML::Client instead of this";

WriteMakefile(
 	'NAME'		=> 'SOAP::Lite::Simple',
	'ABSTRACT'	=> $ABSTRACT,
	'AUTHOR'	=> 'Leo Lapworth',
	'VERSION'	=> $VERSION, # finds $VERSION
	'PREREQ_PM'		=> {
		'SOAP::XML::Client'	=> 1.9,
    	}, 
);
