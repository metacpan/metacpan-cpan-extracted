package RMI::Proxy::DBI::db;

# install overrides to the default proxy options

# The selectall_arrayref method is implemented in C and Perl.  The C implementation is called first,
# and then the Perl implementation is called if the optional attributes hash is present with a "Slice" key.
# For some reason, when this hashref is a proxy, errors occur on the C side, and we never make it back to Perl.

# It's safe to use a proxy here, because DBI::db never attempts to mutlate the hash in a way the caller expects
# to observe later.

$RMI::ProxyObject::DEFAULT_OPTS{"DBI::db"}{"selectall_arrayref"} = { copy => 1 };

1;

