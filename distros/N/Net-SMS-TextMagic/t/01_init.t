use strict;
use warnings;

use Test::More tests => 13;
BEGIN { use_ok('Net::SMS::TextMagic') };

my $sms = Net::SMS::TextMagic->new(USER=>'username', API_ID=>'api_id');

my @subroutines = qw(
	message_send
	account
	message_status
	receive
	delete_reply
	check_number
	contact_api
	set_error
	get_error
	if_error
	get_unprocessed_errors
	if_unprocessed_errors
	);
	
foreach my $sub ( @subroutines ) {
    can_ok($sms, $sub);
}

