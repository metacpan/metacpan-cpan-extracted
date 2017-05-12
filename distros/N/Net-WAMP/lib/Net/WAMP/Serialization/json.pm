package Net::WAMP::Serialization::json;

use JSON ();

use constant {
    serialization => 'json',
    websocket_data_type => 'text',
};

#The following have trouble dealing with anything that isn’t UTF-8;
#but JSON must always be UTF-8, UTF-16, or UTF-32 anyway as per RFC 7159.
#So, any application that wants to send binary data via JSON needs to use
#Base64, hex, or some such.
*stringify = *JSON::encode_json;
*parse = *JSON::decode_json;

#my $_JSON;
#
#sub stringify {
#    return ($_JSON ||= JSON->new()->utf8(0))->encode($_[0]);
#}
#
#sub parse {
#    return ($_JSON ||= JSON->new()->utf8(0))->decode($_[0]);
#}

1;
