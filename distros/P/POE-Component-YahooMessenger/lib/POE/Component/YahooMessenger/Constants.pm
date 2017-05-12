package POE::Component::YahooMessenger::Constants;
use strict;

BEGIN {
    use vars qw(@EXPORT @ISA);

    require Exporter;
    @ISA    = qw(Exporter);
    @EXPORT = qw($Default $MessageHeader $BodySeparater $Options
		 $ReceiveEventCodes $ReceiveEventNames
		 $SendEventCodes $SendEventNames
		 $BodyCodes $BodyNames);
}

use vars @EXPORT;

$Default = {
    hostname      => 'scs.yahoo.com',
    port          => 5050,
};

$Options = {
    to_buddies => 1515563606,
    to_non_buddies => 1515563605,
};

$MessageHeader = 'YMSG';
$BodySeparater = "\xC0\x80";

$ReceiveEventCodes = {
    1  => 'goes_online',
    2  => 'goes_offline',
    3  => 'change_status',
    4  => 'change_normal_status',
    6  => 'receive_message',
    15 => 'new_buddy_alert',
    24 => 'conference_invitation',
    75 => 'toggle_typing',
    76 => 'server_is_alive',
    77 => 'receive_file',
    84 => 'cram_auth_fail',
    85 => 'receive_buddy_list',
    87 => 'challenge_start',
};

$ReceiveEventNames = { reverse %$ReceiveEventCodes };

$SendEventCodes = {
    %$ReceiveEventCodes,
    6  => 'send_message',
    77 => 'send_file',
    84 => 'challenge_response',
    131 => 'add_buddy',
    132 => 'delete_buddy',
};

$SendEventNames = { reverse %$SendEventCodes };

$BodyCodes = {
    0  => 'my_id',
    1  => 'id',
    2  => 'login_nickname',
    3  => 'new_buddy_id',
    4  => 'from',
    5  => 'to',
    6  => 'crypt_salt',
    7  => 'buddy_id',
    8  => 'number_of_online_buddies',
    10 => 'status_code',
    11 => 'session_id',
    13 => 'live',
    14 => 'message',
    15 => 'received_time',
    16 => 'error_message',
    19 => 'status_message',
    20 => 'download_url',
    27 => 'filename',
    28 => 'filesize',
    47 => 'busy_code',
    49 => 'command_name',	# XXX 'FILEXFER'
    50 => 'invitation_from',
    52 => 'invitation_with',	# XXX
    53 => 'download_filename',
    54 => 'protocol',		# XXX 'MSG1.0'
    57 => 'conference_name',
    58 => 'invitation_message',
    59 => 'cookie',
    65 => 'group',
    87 => 'buddy_list',
    94 => 'challenge_string',
    96 => 'crypted_response',
};

$BodyNames = { reverse %$BodyCodes };

1;
