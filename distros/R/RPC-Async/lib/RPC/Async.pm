use strict;
use warnings;

package RPC::Async;

our $VERSION = '1.05';

1;

=head1 NAME

RPC::Async - Asynchronous RPC framework

=head1 DESCRIPTION

This set of module implements remote procedure calls between perl programs. It
is special in that control flow does not halt until the call has completed.
Instead, the call completes in the background until it eventually returns,
triggering a callback function in the client. By using anonymous sub references
(closures) in Perl, such control flow can be made to look quite linear despite
being non-blocking and interleaved.

This module uses L<IO::EventMux>, the event-based frontend to L<select(2)>, to
do parallel I/O without using threads. Users of this module must use
L<IO::EventMux> to control their main loop, but this is still very flexible.

The two ends of this framework are documented in L<RPC::Async::Client> and
L<RPC::Async::Server>.

=head1 AUTHOR

Jonas Jensen <jbj@knef.dk>, Troels Liebe Bentsen <tlb@rapanden.dk> 

=head1 COPYRIGHT

Copyright(C) 2005-2007 Troels Liebe Bentsen

Copyright(C) 2005-2007 Jonas Jensen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
