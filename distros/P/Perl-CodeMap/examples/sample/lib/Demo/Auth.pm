package Demo::Auth;
use strict;
use warnings;
use Demo::Storage;
use Demo::Config;

# Validate an example token.
sub authorize {
    my ($token) = @_;
    return defined $token && length($token) > 0;
}
1;
