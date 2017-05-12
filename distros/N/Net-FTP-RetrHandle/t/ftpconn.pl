


use Net::FTP;
use Net::FTP::RetrHandle;
use IO::Handle;
use Fcntl ':seek';
use Test::More tests => 653;

our $ftp = Net::FTP->new(CPAN_HOST,
			$ENV{DEBUG} ? (Debug => 1) : ()
			)
    or die "Couldn't FTP to : $!\n";
ok($ftp,"Connect to @{[ CPAN_HOST ]}");
ok($ftp->login('ftp','testing@example.com'),"Login anonymously to @{[ CPAN_HOST ]}");
ok($ftp->cwd(CPAN_DIR),"chdir(@{[ CPAN_DIR ]}) on @{[ CPAN_HOST ]}");

1;
