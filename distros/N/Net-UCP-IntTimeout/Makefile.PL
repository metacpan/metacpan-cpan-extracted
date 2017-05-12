use lib 'inc';
use ExtUtils::AutoInstall( -core  => [ ] );

WriteMakefile(
	      NAME              => 'Net::UCP::IntTimeout',
	      VERSION_FROM      => 'lib/Net/UCP/IntTimeout.pm',
	      PREREQ_PM         => {},
	      ($] >= 5.005 ?    
	       (ABSTRACT_FROM  => 'lib/Net/UCP/IntTimeout.pm', 
		AUTHOR         => 'Marco Romano <nemux@cpan.org>') : ()),
);
