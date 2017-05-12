
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'Template::Plugin::NDS_Multi',
	VERSION	         => '3.00',
	($] >= 5.005
	? (ABSTRACT=>'Interface to Data::NDS::Multi* modules',
	   AUTHOR  =>'Sullivan Beck (sbeck@cpan.org)')
	: ()),
	'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
        PL_FILES  => {},
	PREREQ_PM => {
		'Template'            => '0',
		'Template::Plugin'    => '0',
		'Data::NDS::Multiele' => '0',
		'Data::NDS::Multifile'=> '0',
		'Data::NDS::Multisource'=> '0',
		'IO::File'            => '0',
		'Template::Constants' => '0',
		'Test::More'          => '0',
		'Test::Pod'           => '0',
		'Test::Pod::Coverage' => '0',
	},
);
