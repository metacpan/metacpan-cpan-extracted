use lib('blib/lib/');
use Net::Vypress::Chat;
my $vyc = Net::Vypress::Chat->new(
	'localip' => '192.168.0.1',
#	'localip' => '127.0.0.1',
	'debug' => '1'
);
$vyc->startup;
while (1) { $vyc->readsock; }
