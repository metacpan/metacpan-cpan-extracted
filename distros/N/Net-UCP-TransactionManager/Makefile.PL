use lib 'inc';
use ExtUtils::AutoInstall( -core  => [ ] );
WriteMakefile(
	      NAME              => 'Net::UCP::TransactionManager',
	      VERSION_FROM      => 'lib/Net/UCP/TransactionManager.pm',
	      PREREQ_PM         => {},
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM  => 'lib/Net/UCP/TransactionManager.pm',
		AUTHOR         => 'Marco Romano <nemux@cpan.org>') : ()),
	      );
