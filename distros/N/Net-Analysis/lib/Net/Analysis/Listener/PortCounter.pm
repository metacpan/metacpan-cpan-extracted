package Net::Analysis::Listener::PortCounter;
# $Id: Example1.pm 140 2005-10-21 16:31:29Z abworrall $

use strict;
use warnings;
use base qw(Net::Analysis::Listener::Base);
use Data::Dumper;

use Net::Analysis::Packet qw(:all);

my %h;

sub setup {}

sub tcp_packet {
    my ($self, $args) = @_;
    my ($pkt) = $args->{pkt};

    my ($to_port)   = ($pkt->[PKT_SLOT_TO] =~ /:(\d+)$/);
    my ($from_port) = ($pkt->[PKT_SLOT_FROM] =~ /:(\d+)$/);

    $h{sprintf ("%21.21s -> %21.21s", $pkt->[PKT_SLOT_FROM],
                $pkt->[PKT_SLOT_TO])} += length($pkt->[PKT_SLOT_DATA]);

#    $h{sprintf ("%05d->%05d", $from_port, $to_port)} += length($pkt->{data});

#    $h{to}{$to_port}{num_packets}++;
#    $h{to}{$to_port}{data} += length($pkt->{data});
#    $h{from}{$from_port}{num_packets}++;
#    $h{from}{$from_port}{data} += length($pkt->{data});

#    print Dumper $pkt;
}

sub teardown {

    foreach my $pair (sort {$h{$b} <=> $h{$a}} keys %h) {
        printf "%s    % 7d\n", $pair, $h{$pair};
    }
}

1;

__END__

=head1 NAME

Net::Analysis::Listener::PortCounter - broad overview of traffic

=head1 SYNOPSIS

You can invoke this example on a TCP capture file from the command line, as
follows:

 $ perl -MNet::Analysis -e main PortCounter t/t1_google.tcp

=head1 DESCRIPTION

=head1 SEE ALSO

L<Net::Analysis>.

=head1 AUTHOR

Adam B. Worrall, E<lt>worrall@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
