use strict;
use warnings;
use Net::SSLGlue::FTP;

my $ftp = Net::FTP->new( 'ftp.example.com', 
    Passive => 1,
    Debug => 1,
);
$ftp->starttls( SSL_ca_path => '/etc/ssl/certs' )
    or die "tls upgrade failed";
$ftp->login('foo','bar');
print $ftp->ls;

# change protection to clear
$ftp->prot('C');
$ftp->ls;

# stop TLS on control channel
$ftp->stoptls;
$ftp->ls;

