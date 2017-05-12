use Test::More tests => 2;

use Net::SFTP::SftpServer;

ok(1);

my $sftp = Net::SFTP::SftpServer->new();

is( ref $sftp, 'Net::SFTP::SftpServer', 'Sftp class created: ' . ref $sftp);

