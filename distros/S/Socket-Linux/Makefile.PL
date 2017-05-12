
use ExtUtils::MakeMaker;
use ExtUtils::Constant 0.11 'WriteConstants';

WriteMakefile( NAME          => 'Socket::Linux',
	       VERSION_FROM  => 'lib/Socket/Linux.pm',
	       PREREQ_PM     => {},
	       ABSTRACT_FROM => 'lib/Socket/Linux.pm', 
	       AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>',
	       realclean     => { FILES => 'const-c.inc const-xs.inc'} );

my @names = qw( TCP_NODELAY TCP_MAXSEG TCP_CORK TCP_KEEPIDLE
	        TCP_KEEPINTVL TCP_KEEPCNT TCP_SYNCNT TCP_LINGER2
	        TCP_DEFER_ACCEPT TCP_WINDOW_CLAMP TCP_INFO
	        TCP_QUICKACK TCP_CONGESTION TCP_MD5SIG

	        TCPOPT_EOL TCPOPT_NOP TCPOPT_MAXSEG TCPOLEN_MAXSEG
	        TCPOPT_WINDOW TCPOLEN_WINDOW TCPOPT_SACK_PERMITTED
	        TCPOLEN_SACK_PERMITTED TCPOPT_SACK TCPOPT_TIMESTAMP
	        TCPOLEN_TIMESTAMP TCPOLEN_TSTAMP_APPA
	        TCPOPT_TSTAMP_HDR

	        TCP_MSS TCP_MAXWIN TCP_MAX_WINSHIFT SOL_TCP

	        TCPI_OPT_TIMESTAMPS TCPI_OPT_SACK TCPI_OPT_WSCALE
	        TCPI_OPT_ECN

	        TCP_MD5SIG_MAXKEYLEN );

WriteConstants( ($] > 5.009002 ? (PROXYSUBS => 1) : ()),
		NAME  => 'Socket::Linux',
		NAMES => \@names );
