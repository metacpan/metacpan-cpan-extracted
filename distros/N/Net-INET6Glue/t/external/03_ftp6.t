use strict;
use Net::INET6Glue::FTP;
use Net::FTP;

# check if we can reach ftp6.netbsd.org
$Net::INET6Glue::INET_is_INET6::INET6CLASS->new( 'ftp6.netbsd.org:21' ) or do {
    print "1..0 # ftp6.netbsd.org not reachable\n";
    exit
};

print "1..6\n";
for my $pasv ( 0,1 ) {
    if ( my $ftp = Net::FTP->new( 'ftp6.netbsd.org', Passive => $pasv )) {
	print "ok # connect\n";
	print $ftp->login( 'ftp','cpantest@example.com' ) 
	    ? "ok # login\n" 
	    : "not ok # login\n";
	my @files = $ftp->ls;
	print @files > 0 
	    ? "ok # ls pasv=$pasv\n"
	    : "not ok # no files in ls pasv=$pasv\n";
    } else {
	print "not ok # connect passive=$pasv failed\n" for (1..3);
    }
}

