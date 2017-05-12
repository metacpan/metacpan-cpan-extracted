package Net::IMAP::Server::Test::Auth;
use base 'Net::IMAP::Server::DefaultAuth';

use strict;
use warnings;

sub auth_plain {
    my $self = shift;
    my ($user, $pass) = (@_);
    return unless $pass eq "password";
    $self->user($user);
    return 1;
}

1;
