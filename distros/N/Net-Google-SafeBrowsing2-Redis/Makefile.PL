use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Google::SafeBrowsing2::Redis',
    VERSION_FROM      => 'lib/Net/Google/SafeBrowsing2/Redis.pm', # finds $VERSION
    PREREQ_PM         => {
		Net::Google::SafeBrowsing2::Storage	=> '0.4',
		Net::Google::SafeBrowsing2			=> 0,
		Redis::hiredis						=> 0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Google/SafeBrowsing2/Redis.pm', # retrieve abstract from module
       AUTHOR         => 'Julien Sobrier <jsobrier@localdomain>') : ()),
);
