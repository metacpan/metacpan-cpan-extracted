use Test;
BEGIN { plan tests => 6 }

use Net::YahooMessenger::CRAM;
ok(1);
my $cram = Net::YahooMessenger::CRAM->new;
ok( defined $cram );
$cram->set_challenge_string('aiueo0kakikukeko1sasis--');
$cram->set_id('hello');
$cram->set_password('world');
@_ = $cram->get_response_strings();
ok( $_[0] eq '42cXAt3YU6QEknuf2iTZlg--' );
ok( $_[1] eq 'TrHERqKG9EbfjbK5KiaQkg--' );

$cram->set_challenge_string('1234567890123456789012--');
$cram->set_id('user');
$cram->set_password('password');
@_ = $cram->get_response_strings();
ok( $_[0] eq 'uu67npQcuPxQ82OIEd13Bw--' );
ok( $_[1] eq 'UoPYnZkCdGaoPESzqkEJqw--' );
