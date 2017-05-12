package RPC::Any::Package::XMLRPC;
use strict;
use RPC::XML;

BEGIN { *rpc_type = \&type };

sub type {
    my ($self, $type, $value) = @_;

    local $RPC::XML::ERROR;
    local $RPC::XML::ALLOW_NIL = 1;
    return RPC::XML::nil->new() if !defined $value;

    if (lc($type) eq 'datetime') {
        $type = 'datetime_iso8601';
    }
    my $type_class = "RPC::XML::$type";
    my $new_type = $type_class->new($value);
    die $RPC::XML::ERROR if $RPC::XML::ERROR;
    return $new_type;
}

__PACKAGE__;