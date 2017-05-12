package Net::IMAP::Server::Command::Examine;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command::Select/;

# See Net::IMAP::Server::Command::Select, which special-cases the
# "Examine" command to force the mailbox read-only

1;
