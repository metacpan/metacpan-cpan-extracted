use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SOAP::ISIWoK',
    VERSION_FROM      => 'lib/SOAP/ISIWoK.pm', # finds $VERSION
    PREREQ_PM         => {
		'SOAP::Lite' => 0.6,
		'HTTP::Cookies' => 0,
		'MIME::Base64' => 0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SOAP/ISIWoK.pm', # retrieve abstract from module
       AUTHOR         => 'Tim Brody <tdb2@ecs.soton.ac.uk>') : ()),
	dist              => {
		(-d '.git' ? (PREOP => 'git --no-pager log --pretty="format:%ai %aN %n%n%x09* %s%d%n" > $(DISTVNAME)/Changes') : ()),
		COMPRESS => 'gzip -9f',
		SUFFIX => 'gz',
	},
	META_MERGE => {
		resources         => {
			url     =>  'git://github.com/timbrody/soap-isiwok.git',
			web     =>  'https://github.com/timbrody/soap-isiwok',
			type    =>  'git',
		},
	}
);
