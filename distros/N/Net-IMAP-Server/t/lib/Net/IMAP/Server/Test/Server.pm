package Net::IMAP::Server::Test::Server;
use base 'Net::IMAP::Server';

use strict;
use warnings;

sub write_to_log_hook {
    my $self = shift;
    my ($level, $msg) = @_;
    Test::More::diag($msg) if $ENV{TEST_VERBOSE};
}

1;
