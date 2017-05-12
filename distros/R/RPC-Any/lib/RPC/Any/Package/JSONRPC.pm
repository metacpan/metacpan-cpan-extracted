package RPC::Any::Package::JSONRPC;
use strict;
use JSON;
use MIME::Base64;

BEGIN { *rpc_type = \&type };

sub type {
    my ($self, $type, $value) = @_;

    # This is the only type that does something special with undef.
    if ($type eq 'boolean') {
        return $value ? JSON::true : JSON::false;
    }

    return JSON::null if !defined $value or $type eq 'nil';

    my $retval = $value;

    if ($type eq 'int') {
        $retval = int($value);
    }
    if ($type eq 'double') {
        $retval = 0.0 + $value;
    }
    elsif ($type eq 'string') {
        # Forces string context, so that JSON will make it a string.
        $retval = "$value";
    }
    elsif ($type eq 'base64') {
        utf8::encode($retval) if utf8::is_utf8($retval);
        $retval = encode_base64($value, '');
    }

    return $retval;
}

__PACKAGE__;