package Net::Analysis::Listener::Example3;
# $Id: Example3.pm 143 2005-11-03 17:36:58Z abworrall $

use strict;
use warnings;
use base qw(Net::Analysis::Listener::Base);

sub http_transaction {
    my ($self, $args) = @_;
    my ($req)       = $args->{req};         # isa HTTP::Request
    my ($req_mono)  = $args->{req_mono};    # isa Net::Analysis::TCPMonologue
    my ($resp_mono) = $args->{resp_mono};   # isa Net::Analysis::TCPMonologue

    # Print out time between sending last part of request, and receiving
    #  first part of response.
    # (Note; these are Net::Analsysis::Time objects)
    my ($network_wait_time) = $resp_mono->t_start() - $req_mono->t_end();
    printf "%-50.50s: %8.2f\n", $req->uri(), $network_wait_time;
}

1;

=head1 NAME

Net::Analysis::Listener::Example3 - looking at HTTP transactions

=head1 SYNOPSIS

 package Net::Analysis::Listener::Example3;

 use strict;
 use warnings;
 use base qw(Net::Analysis::Listener::Base);

 sub http_transaction {
     my ($self, $args) = @_;
     my ($req)       = $args->{req};         # isa HTTP::Request
     my ($req_mono)  = $args->{req_mono};    # isa Net::Analysis::TCPMonologue
     my ($resp_mono) = $args->{resp_mono};   # isa Net::Analysis::TCPMonologue

     # Print out time between sending last part of request, and receiving
     #  first part of response.
     # (Note; these are Net::Analsysis::Time objects)
     my ($network_wait_time) = $resp_mono->t_start() - $req_mono->t_end();
     printf "%-50.50s: %8.2f\n", $req->uri(), $network_wait_time;
 }

 1;

You can invoke this example on a TCP capture file from the command line, as
follows:

 $ perl -MNet::Analysis -e main HTTP Example3 t/t1_google.tcp

Note the regex parameter being passed to the Example2 listener.

=head1 DESCRIPTION

How to sit on top of L<Net::Analysis::Listener::HTTP>. Note that you need to
load the HTTP listener as well as Example3 in the Perl command line ! If you
don't do this, then only the TCP listener will be loaded, no
C<http_transaction> events will be emitted, and so Example3 will listen in
vain.

Other gotcahs; the C<t_start> and C<t_end> methods for TCPMonologue return
L<Net::Analysis::Time> objects, which while useful for certain things, might
not be what you want. You can turn them into floating point seconds easily
enough though.

=head1 SEE ALSO

L<Net::Analysis>,
L<Net::Analysis::Time>,
L<Net::Analysis::Listener::HTTP>.

=head1 AUTHOR

Adam B. Worrall, E<lt>worrall@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
