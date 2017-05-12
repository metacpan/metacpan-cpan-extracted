# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-UCP-Common.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
use strict;
BEGIN { use_ok('Net::UCP::Common') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $h = new Net::UCP::Common;

ok(defined($h),                                'handler to Net::UCP::Common stuff is defined');
ok(Net::UCP::Common::ETX eq chr(3),            'ETX constant');
ok(Net::UCP::Common::STX eq chr(2),            'STX constant');
ok(Net::UCP::Common::UCP_DELIMITER eq "/",     'UCP protocol string delimiter');
ok(Net::UCP::Common::ACK eq "A",               'ACK is ok and accessible');
ok(Net::UCP::Common::NACK eq "N",              'NAC is ok and accessible');
ok(Net::UCP::Common->checksum("Marco Romano") eq "7E",       'checksum for "Marco Romano" string is 7E');
ok(Net::UCP::Common->data_len("Marco Romano") eq "00029",    'length of "Marco Romano" string is 00029');
ok(Net::UCP::Common->ia5_decode(414141) eq "AAA",            'ia5 decoding works');
ok(Net::UCP::Common->ia5_encode("AAA") eq "414141",          'ia5 encode works');
ok(Net::UCP::Common->encode_7bit("Marco") eq "09CDB07CFC06", '7bit encoding works...');