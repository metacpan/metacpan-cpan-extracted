package Net::Analysis::Listener::Example2;
# $Id: Example2.pm 143 2005-11-03 17:36:58Z abworrall $

use strict;
use warnings;
use base qw(Net::Analysis::Listener::Base);

sub tcp_monologue {
    my ($self, $args) = @_;
    my ($mono) = $args->{monologue};    # isa Net::Analysis::TCPMonologue
    my ($pkt)  = $mono->first_packet(); # isa Net::Analysis::Packet
    my ($from) = $pkt->{from};
    my ($time) = $pkt->{time}->as_string('full');

    printf "(%s)  %-22.22s % 6d bytes", $time, $from, $mono->length();

    if ($self->{regex}) {
        if ($mono->data() =~ /(.{0,10}$self->{regex}.{0,10})/i) {
            print " ** regex matched: '$1'";
        }
    }

    print "\n";
}

1;

=head1 NAME

Net::Analysis::Listener::Example2 - accessing TCP info

=head1 SYNOPSIS

 package Net::Analysis::Listener::Example2;

 use strict;
 use warnings;
 use base qw(Net::Analysis::Listener::Base);

 sub tcp_monologue {
     my ($self, $args) = @_;
     my ($mono) = $args->{monologue};    # isa Net::Analysis::TCPMonologue
     my ($pkt)  = $mono->first_packet(); # isa Net::Analysis::Packet
     my ($from) = $pkt->{from};
     my ($time) = $pkt->{time}->as_string('full');

     printf "(%s)  %-22.22s % 6d bytes", $time, $from, $mono->length();

     if ($self->{regex}) {
         if ($mono->data() =~ /(.{0,10}$self->{regex}.{0,10})/i) {
             print " ** regex matched: '$1'";
         }
     }

     print "\n";
 }

 1;

You can invoke this example on a TCP capture file from the command line, as
follows:

 $ perl -MNet::Analysis -e main Example2,regex=img t/t1_google.tcp

Note the regex parameter being passed to the Example2 listener.

=head1 DESCRIPTION

This Listener prints a brief summary of the monologue traffic, and
optionally greps the monologue data for a regex, if one is passed
via config into $self.

=head1 SEE ALSO

L<Net::Analysis>.

=head1 AUTHOR

Adam B. Worrall, E<lt>worrall@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
