use strict;
use warnings;
use Crypt::PasswdMD5;
use Test::More tests => 7;
use POE::Component::Server::IRC::Common qw(:ALL);

my $plain = 'foocow99';
my $crypt = mkpasswd($plain);
is(crypt($plain, $crypt), $crypt, 'Crypt mkpasswd');

my $MD5Magic = '$1$';
my $md5 = mkpasswd($plain, 'md5', 1);

my $salt = $md5;
$salt =~ s/^\Q$MD5Magic//; 
$salt =~ s/^(.*)\$/$1/; 
$salt = substr( $salt, 0, 8 );
is(unix_md5_crypt($plain, $salt), $md5, 'MD5 mkpasswd');

my $apr = mkpasswd($plain, 'apache', 1);
$salt = $apr; 
$MD5Magic = '$apr1$';
$salt =~ s/^\Q$MD5Magic//; 
$salt =~ s/^(.*)\$/$1/; 
$salt = substr( $salt, 0, 8 );
is(apache_md5_crypt($plain, $salt), $apr, 'Apache MD5 mkpasswd');
ok(chkpasswd($plain, $plain), 'Plain-text chkpasswd');
ok(chkpasswd($plain, $crypt), 'Crypt chkpasswd');
ok(chkpasswd($plain, $md5), 'MD5 chkpasswd');
ok(chkpasswd($plain, $apr), 'Apache MD5 chkpasswd');
