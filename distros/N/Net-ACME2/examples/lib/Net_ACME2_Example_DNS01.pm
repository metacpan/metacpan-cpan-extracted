package Net_ACME2_Example_DNS01;

use strict;
use warnings;

use constant {
    CAN_WILDCARD => 1,

    _CHALLENGE_TYPE => 'dns-01',
};

sub _authz_handler {
    my ($class, $acme, $authz_obj) = @_;

    my $zone = $authz_obj->identifier()->{'value'};

    my $challenge = $class->_get_challenge_from_authz($authz_obj);

    my $rec_name = $challenge->get_record_name();
    my $rec_value = $challenge->get_record_value($acme);

    print "$/Create a TXT record for:$/$/\t$rec_name.$zone.$/$/";
    print "… with the following value:$/$/";

    print "\t$rec_value$/$/";

    print "Then press ENTER.$/";

    <STDIN>;

    return $challenge;
}

1;
