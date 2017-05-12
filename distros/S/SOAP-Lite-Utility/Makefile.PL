use ExtUtils::MakeMaker;
#
my %opts = (
	    'NAME'	   => 'SOAP::Lite::Utility',
	    'VERSION_FROM' => "lib/SOAP/Lite/Utility.pm",
	    'EXE_FILES' => [ qw( ) ],
	    'PREREQ_PM' => { 
		'SOAP::Lite'      => 0,
	    },
	    );

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{AUTHOR}   = 'Bryce Harrington <bryce@bryceharrington.org>';
    $opts{ABSTRACT} = 'Utilities for SOAP::Lite client programs';
}
 
WriteMakefile( %opts )

