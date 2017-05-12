use Test::More tests => 14;
use Mojo::TFTPd;

my $tftpd = Mojo::TFTPd->new;
my ($host, $port);

$tftpd->listen('*');
($host, $port) = $tftpd->_parse_listen;
is $host, '0.0.0.0',  'right host';
is $port, 69,         'right port';

$tftpd->listen('1.1.1.1');
($host, $port) = $tftpd->_parse_listen;
is $host, '1.1.1.1',  'right host';
is $port, 69,         'right port';

$tftpd->listen('1.1.1.1:100');
($host, $port) = $tftpd->_parse_listen;
is $host, '1.1.1.1',  'right host';
is $port, 100,        'right port';

$tftpd->listen('tftp://*');
($host, $port) = $tftpd->_parse_listen;
is $host, '0.0.0.0',  'right host';
is $port, 69,         'right port';

$tftpd->listen('tftp://1.1.1.1');
($host, $port) = $tftpd->_parse_listen;
is $host, '1.1.1.1',  'right host';
is $port, 69,         'right port';

$tftpd->listen('tftp://1.1.1.1:100');
($host, $port) = $tftpd->_parse_listen;
is $host, '1.1.1.1',  'right host';
is $port, 100,         'right port';

$tftpd->listen('foo://1.1.1.1');
($host, $port) = $tftpd->_parse_listen;
is $host, '1.1.1.1',  'right host';
is $port, 69,         'right port';


