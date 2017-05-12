#use 5.012003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SMTPS',
    VERSION_FROM      => 'lib/Net/SMTPS.pm', # finds $VERSION
    PREREQ_PM         => {
			'Net::SMTP'	=> 2.0,
			'IO::Socket::SSL' => 1.0,
			'Authen::SASL' => 2.0,
			},
    NO_MYMETA		=> 'true',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/SMTPS.pm', # retrieve abstract from module
       AUTHOR         => 'Tomo.M <tomo@cpan.org>') : ()),
    LICENSE           => 'perl',
);
