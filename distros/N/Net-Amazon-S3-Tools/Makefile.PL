use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Net::Amazon::S3::Tools',
    VERSION_FROM      => 'lib/Net/Amazon/S3/Tools.pm',
    PREREQ_PM         => {
	'Pod::Usage' => 1,
	'Getopt::Long' => 1,
	'Getopt::ArgvFile' => 0,
	'File::HomeDir' => 0,
	'Net::Amazon::S3' => 0,
	'Net::Amazon::S3::Bucket' => 0,
	# todo
	# Net::Amazon::S3 already uses XML::LibXML & XML::LibXML::XPathContext
	# so do rewrite to avoid need for XML::Writer
	'XML::Writer' => 0,
    },
    'EXE_FILES' => [ 's3acl', 's3ls',
		     's3get', 's3put',
		     's3rm', 
		     's3mkbucket', 's3rmbucket' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Command line tools for Amazon AWS S3',
       AUTHOR         => 'Mark Atwood <mark@fallenpegasus.com>') : ()),
);
