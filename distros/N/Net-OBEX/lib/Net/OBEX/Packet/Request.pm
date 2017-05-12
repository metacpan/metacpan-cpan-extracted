package Net::OBEX::Packet::Request;

use strict;
use warnings;

use Carp;
use Net::OBEX::Packet::Request::Connect;
use Net::OBEX::Packet::Request::Disconnect;
use Net::OBEX::Packet::Request::Get;
use Net::OBEX::Packet::Request::Put;
use Net::OBEX::Packet::Request::SetPath;
use Net::OBEX::Packet::Request::Abort;

our $VERSION = '1.001001'; # VERSION

my %Valid_Packets = map { $_ => 1 }
                        qw(connect disconnect get put setpath abort);

my %Make_Packet = (
    connect     => sub { _make_connect(    shift ); },
    disconnect  => sub { _make_disconnect( shift ); },
    get         => sub { _make_get(        shift ); },
    put         => sub { _make_put(        shift ); },
    setpath     => sub { _make_setpath(    shift ); },
    abort       => sub { _make_abort(      shift ); },
);

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub make {
    my $self = shift;

    croak "Must have even number of arguments to new()"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    croak "Invalid packet name was specified (the `packet` argument)"
        unless exists $Valid_Packets{ $args{packet} };

    my $make_ref = $Make_Packet{ $args{packet} };
    delete $args{packet};
    return $make_ref->( \%args );
}

sub _make_connect {
    my $args = shift;
    return Net::OBEX::Packet::Request::Connect->new( %$args )->make;
}

sub _make_disconnect {
    my $args = shift;
    return Net::OBEX::Packet::Request::Disconnect->new( %$args )->make;
}

sub _make_get {
    my $args = shift;
    return Net::OBEX::Packet::Request::Get->new( %$args )->make;
}

sub _make_put {
    my $args = shift;
    return Net::OBEX::Packet::Request::Put->new( %$args )->make;
}

sub _make_setpath {
    my $args = shift;
    return Net::OBEX::Packet::Request::SetPath->new( %$args )->make;
}

sub _make_abort {
    my $args = shift;
    return Net::OBEX::Packet::Request::Abort->new( %$args )->make;
}

1;

__END__

=encoding utf8

=for stopwords AnnoCPAN RT setpath

=head1 NAME

Net::OBEX::Packet::Request - create OBEX protocol request packets.

=head1 SYNOPSIS

    use Net::OBEX::Packet::Request;
    use Net::OBEX::Packet::Headers;

    my $head = Net::OBEX::Packet::Headers->new;
    my $req = Net::OBEX::Packet::Request->new;

    my $obexftp_target
    = $head->make( target  => pack 'H*', 'F9EC7BC4953C11D2984E525400DC9E09');

    my $connect_packet = $req->make(
        packet  => 'connect',
        headers => [ $obexftp_target ],
    );

    # send $connect_packet down the wire

    my $disconnect_packet = $req->make( packet => 'disconnect' );
    # this one can go too now.

=head1 DESCRIPTION

B<WARNING!!! This module is in an early alpha stage. It is recommended
that you use it only for testing.>

The module provides means to create raw OBEX packets ready to go
down the wire. The module does not provide Headers I<creation>, to
create packet headers use L<Net::OBEX::Packet::Headers>

=head1 CONSTRUCTOR

=head2 new

    my $req = Net::OBEX::Packet::Request->new;

Takes no arguments, returns a freshly baked C<Net::OBEX::Packet::Request>
object ready for request packet production.

=head1 METHODS

=head2 make

    my $connect_packet = $req->make(
        packet  => 'connect',
        headers => [ $obexftp_target ],
    );

    my $disconnect_packet = $req->make( packet => 'disconnect' );

Takes several name/value arguments. The C<packet> argument indicates
which packet to construct, the rest of the arguments will go directly
into a specific packet's constructor (C<new()>) method. The following
is a list of valid C<packet> argument values with a corresponding
module, read the documentation of that module's constructor to find out
the rest of the possible arguments to C<make()> method.

=head3 connect

Will make OBEX C<Connect> packet,
see L<Net::OBEX::Packet::Request::Connect>

=head3 disconnect

Will make OBEX C<Disconnect> packet,
see L<Net::OBEX::Packet::Request::Disconnect>

=head3 setpath

Will make OBEX C<SetPath> packet,
see L<Net::OBEX::Packet::Request::SetPath>

=head3 get

Will make OBEX C<Get> packet,
see L<Net::OBEX::Packet::Request::Get>

=head3 put

Will make OBEX C<Get> packet,
see L<Net::OBEX::Packet::Request::Put>

=head3 abort

Will make OBEX C<Abort> packet,
see L<Net::OBEX::Packet::Request::Abort>

The rest of packets are yet to be implemented.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Net-OBEX>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Net-OBEX/issues>

If you can't access GitHub, you can email your request
to C<bug-Net-OBEX at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut