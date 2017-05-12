package POE::Component::LaDBI::Commands;

use v5.6.0;
use strict;
use warnings;

our $VERSION = '1.0';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(@COMMANDS);

our @COMMANDS =
  qw(
     CONNECT
     DISCONNECT
     PREPARE
     FINISH
     EXECUTE
     ROWS
     FETCHROW
     FETCHROW_HASH
     FETCHALL
     FETCHALL_HASH
     PING
     DO
     BEGIN_WORK
     COMMIT
     ROLLBACK
     SELECTALL
     SELECTALL_HASH
     SELECTCOL
     SELECTROW
     QUOTE
    );

1;
__END__

=head1 NAME

POE::Component::LaDBI::Commands - Package that contains some constants other
LaDBI packages might use.

=head1 SYNOPSIS

  use POE::Component::LaDBI::Commands;

=head1 DESCRIPTION

Automatically imports the C<@COMMANDS> array.

=head2 EXPORT

This package exports the C<@COMMANDS> array. This array is the list of
supported commands C<POE::Component::LaDBI::Request> can build and
C<POE::Component::LaDBI::Engine> can execute.

=head1 AUTHOR

Sean Egan, seanegan@bigfoot.com

=head1 SEE ALSO

L<perl>, L<POE::Component::LaDBI::Request>, L<POE::Component::LaDBI::Response>,
L<POE::Component::LaDBI::Engine>.

=cut
