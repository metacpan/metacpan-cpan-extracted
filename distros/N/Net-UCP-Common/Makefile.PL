use lib 'inc';
use ExtUtils::AutoInstall( -core  => [ ] );
WriteMakefile(
	      NAME              => 'Net::UCP::Common',
	      VERSION_FROM      => 'lib/Net/UCP/Common.pm',
	      PREREQ_PM         => {}, 
	      ($] >= 5.005 ?    
	       (ABSTRACT_FROM  => 'lib/Net/UCP/Common.pm', 
		AUTHOR         => 'Marco Romano <nemux@cpan.org>') : ()),
	      );
