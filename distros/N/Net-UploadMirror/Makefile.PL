#------------------------------------------------
 use ExtUtils::MakeMaker;
#------------------------------------------------
 WriteMakefile(
 	NAME		=> 'Net::UploadMirror',
 	VERSION_FROM	=> 'lib/Net/UploadMirror.pm',	# finds $VERSION
 	PREREQ_PM	=> {
 		'Net::MirrorDir'	=> '0.19', 
 		'Storable'		=> '0',
 		},					# e.g., Module::Name => 1.1
 	($] >= 5.005 ?					## Add these new keywords supported since 5.005
 	(ABSTRACT_FROM => 'lib/Net/UploadMirror.pm',	# retrieve abstract from module
 	AUTHOR	=> 'Torsten Knorr <create-soft@tiscali.de>') : ()),
 	);
#------------------------------------------------
