use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Akismet::Protocol',
    VERSION_FROM      => 'lib/Net/Akismet/Protocol.pm', # finds $VERSION
    PREREQ_PM         => {
		'LWP'	=> '5.09',
		'Moose' => 0,
	}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Akismet/Protocol.pm', # retrieve abstract from module
       AUTHOR         => 'Marcus Ramberg <mramberg@cpan.org>') : ()),
);
