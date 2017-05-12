use strict;
use warnings;
package Net::OTServ;

# ABSTRACT: Retrieve status information about Open Tibia Servers
our $VERSION = '0.004'; # VERSION

use Carp;
use IO::Socket;
use IO::Socket::Timeout;
use XML::Hash::XS;

=pod

=encoding utf8

=head1 NAME

Net::OTServ - Retrieve status information about Open Tibia Servers


=head1 SYNOPSIS

    use Net::OTServ;

    my $status = Net::OTServ::status("127.0.0.1", 7171);
    print "We got $status->{players}{online} players online!\n"


=head1 DESCRIPTION

Open Tibia servers offer a XML interface to query online count, client version and other information.

=head1 METHODS AND ARGUMENTS

=over 4

=item status($ip [, $port])

Retrieves the status of specified OTServ as a hash reference. If C<$port> is omitted, the default 7171 is assumed.

=cut

sub status {
    my $ip = shift;
    my $port = shift || 7171;
    my $timeout = 1;

    my $ot = IO::Socket::INET->new(
        PeerAddr => $ip,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => $timeout, # connection timeout
    ) or croak "OTServ at $ip:$port is offline.";
    IO::Socket::Timeout->enable_timeouts_on($ot);
    $ot->read_timeout($timeout);
    $ot->write_timeout($timeout);

    $ot->write("\x06\x00\xFF\xFF\x69\x6E\x66\x6F");
    my $xml; $ot->recv($xml, 1500);
    $xml or croak "Server at $ip:$port doesn't reply.";
    my $status; eval { $status = xml2hash $xml };
    $status and !$@
        or croak "Server at $ip:$port doesn't reply in XML.";

    
    return $status;
}



1;
__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Net-OTServ>

=head1 SEE ALSO

L<Game::Tibia::Packet|Game::Tibia::Packet>

L<https://github.com/opentibia/server>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
