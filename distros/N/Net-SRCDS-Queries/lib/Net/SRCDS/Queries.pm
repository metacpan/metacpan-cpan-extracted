package Net::SRCDS::Queries;

use warnings;
use strict;
use version; our $VERSION = qv('0.0.5');
use Carp qw(croak);
use IO::Socket::INET;
use IO::Select;
use base qw(Net::SRCDS::Queries::Parser);

# implemented queries
# see http://developer.valvesoftware.com/wiki/Source_Server_Queries
# for all queries.
#
use constant GETCHALLENGE => "\xFF\xFF\xFF\xFF\x57";
use constant A2S_INFO     => "\xFF\xFF\xFF\xFFTSource Engine Query\0";
use constant A2S_PLAYER   => "\xFF\xFF\xFF\xFF\x55";
use constant A2S_RULES    => "\xFF\xFF\xFF\xFF\x56";
use constant MAX_SOCKBUF  => 65535;

sub new {
    my( $class, %args ) = @_;

    my $socket = IO::Socket::INET->new(
        Proto    => 'udp',
        Blocking => 0,
        LocalPort => $args{LocalPort} || 0,
    ) or croak "cannot bind socket : $!";
    my $select = IO::Select->new($socket);
    my $self   = {
        socket   => $socket,
        select   => $select,
        servers  => [],
        timeout  => $args{timeout} || 3,
        encoding => $args{encoding} || undef,
    };
    $self->{float_order} =
        unpack( 'H*', pack( 'f', 1.05 ) ) eq '6666863f' ? 0 : 1;
    bless $self, $class;
}

sub add_server {
    my( $self, $addr, $port ) = @_;
    push @{ $self->{servers} }, { addr => $addr, port => $port };
}

sub get_all {
    my($self)   = @_;
    my $select  = $self->{select};
    my $timeout = $self->{timeout};
    for my $s ( @{ $self->{servers} } ) {
        my $dest = sockaddr_in $s->{port}, inet_aton $s->{addr};
        $self->send_a2s_info($dest);
        $self->send_challenge($dest);
    }
    my $finished = {};
LOOP: while (1) {
        my @ready = $select->can_read($timeout);
        for my $fh (@ready) {
            my $sender = $fh->recv( my $buf, MAX_SOCKBUF );
            my( $port, $addr ) = sockaddr_in $sender;
            my $server = sprintf "%s:%s", inet_ntoa($addr), $port;
            my $result = $self->parse_packet( $buf, $server, $sender );
            my $sr = $self->{results}->{$server};
            if ( exists $sr->{player} and exists $sr->{rules} ) {
                $finished->{$server}++;
            }
            last LOOP
                if scalar keys %{$finished} >= scalar @{ $self->{servers} };
        }
        # exit loop when you get nothing
        unless (@ready) {
            warn "no ready\n";
            last LOOP;
        }
    }
    return $self->{results};
}

sub send_challenge {
    my( $self, $dest ) = @_;
    my $socket = $self->{socket};
    $socket->send( GETCHALLENGE, 0, $dest );
}

sub send_a2s_info {
    my( $self, $dest ) = @_;
    my $socket = $self->{socket};
    $socket->send( A2S_INFO, 0, $dest );
}

sub send_a2s_player {
    my( $self, $dest, $cnum ) = @_;
    my $socket = $self->{socket};
    $socket->send( A2S_PLAYER . $cnum, 0, $dest );
}

sub send_a2s_rules {
    my( $self, $dest, $cnum ) = @_;
    my $socket = $self->{socket};
    $socket->send( A2S_RULES . $cnum, 0, $dest );
}

sub get_result {
    my($self) = @_;
    return $self->{results};
}

1;
__END__

=head1 NAME

Net::SRCDS::Queries - Perl interface to Source Server Queries


=head1 VERSION

This document describes Net::SRCDS::Queries version 0.0.4


=head1 SYNOPSIS

    use Net::SRCDS::Queries;
    use IO::Interface::Simple;
    use Term::Encoding qw(term_encoding);
    use YAML;

    # SRCDS is listening on local server, local address
    my $if       = IO::Interface::Simple->new('eth0');
    my $addr     = $if->address;
    my $port     = 27015;
    my $encoding = term_encoding;

    my $q = Net::SRCDS::Queries->new(
        encoding => $encoding,  # set encoding to convert from utf8
                                # for A2S_PLAYER query.
                                #
        timeout  => 5,          # change timeout. default is 3 seconds
    );
    $q->add_server( $addr, $port );
    warn YAML::Dump $q->get_all;


=head1 DESCRIPTION

This module is a Perl interface to the Valve Source Server Queries.
See L<http://developer.valvesoftware.com/wiki/Source_Server_Queries>
for details.

=head2 Methods

=over

=item new

    my $q = Net::SRCDS::Queries->new(
        encoding => $encoding,  # set encoding to convert from utf8
                                # for a2s_players query.
        timeout  => 5,          # change timeout. default is 3 seconds
    );

This creates an object. If encoding name is given,
convert player name from utf8 to specified encoding.

=item add_server

    $q->add_server( $addr, $port );

adds server to server list for get_all method.

=item get_all

    my $result = $q->get_all;

send A2S_INFO, A2S_SERVERQUERY_GETCHALLENGE, A2S_RULES, A2S_PLAYER to
server list and retrieve result.

=item send_challenge

    my $dest = sockaddr_in $port, inet_aton $addr;
    $self->send_challenge($dest);

send A2S_SERVERQUERY_GETCHALLENGE packet to the destination $dest.

=item send_a2s_info

    my $dest = sockaddr_in $port, inet_aton $addr;
    $self->send_a2s_info($dest);

send A2S_INFO packet to the destination $dest.

=item send_a2s_player

    my $dest = sockaddr_in $port, inet_aton $addr;
    $self->send_a2s_player( $dest, $challenge );

send A2S_PLAYER packet to the destination $dest.

=item send_a2s_rules

    my $dest = sockaddr_in $port, inet_aton $addr;
    $self->send_a2s_rules( $dest, $challenge );

send A2S_RULES packet to the destination $dest.

=item get_result

    my $result = $a2s->get_result;

retrieve result data

=back

=head1 CONFIGURATION AND ENVIRONMENT

Net::SRCDS::Queries requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-srcds-queries@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Masanori Hara  C<< <massa.hara at gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Masanori Hara C<< <massa.hara at gmail.com> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
