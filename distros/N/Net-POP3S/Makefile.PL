#use 5.012003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::POP3S',
    VERSION_FROM      => 'lib/Net/POP3S.pm', # finds $VERSION
    PREREQ_PM         => {
			'Net::POP3'	=> 2.0,
			'IO::Socket::SSL' => 1.0,
			'Authen::SASL' => 2.0,
			},
    NO_MYMETA         => 'true',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/POP3S.pm', # retrieve abstract from module
       AUTHOR         => 'Tomo <tomo_at_cpan.org>') : ()),
    LICENSE           => 'perl',
);
