use strict;
use warnings;
use Net::SSLGlue::FTP;

my $ftp = Net::FTP->new( 'ftp.example.com', 
    SSL => 1, 
    SSL_ca_path => '/etc/ssl/certs',
    Passive => 1,
    Debug => 1,
);
$ftp->login('foo','bar');
print $ftp->ls;
