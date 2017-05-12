package Net::OBEX::Packet::Request::SetPath;

use strict;
use warnings;

use Carp;
use base 'Net::OBEX::Packet::Request::Base';
our $VERSION = '1.001001'; # VERSION

sub new {
    my $class = shift;
    croak "Must have even number of arguments to new()"
        if @_ & 1;
    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    %args = (
        do_up     => 0,
        no_create => 1,
        constants => "\x00",
        headers   => [],

        %args,
    );

    my $self = bless \%args, $class;

    my $flags = $args{no_create} ? '1' : '0';
    $flags .= $args{do_up}      ? '1' : '0';
    $self->flags( pack 'B8', '000000' . $flags );

    return $self;
}

sub make {
    my $self = shift;

    my $packet;
    my $headers = join '', @{ $self->headers };
    if ( $self->do_up and not length $headers ) {
        $packet = $self->flags . $self->constants;
    }
    else {
        $packet = $self->flags . $self->constants . $headers;
    }

    return $self->raw("\x85" . pack('n', 3 + length $packet) . $packet);
}

sub flags {
    my $self = shift;
    if ( @_ ) {
        $self->{ flags } = shift;
    }
    return $self->{ flags };
}

sub do_up {
    my $self = shift;
    if ( @_ ) {
        $self->{ do_up } = shift;
    }
    return $self->{ do_up };
}

sub constants {
    my $self = shift;
    if ( @_ ) {
        $self->{ constants } = shift;
    }
    return $self->{ constants };
}

sub no_create {
    my $self = shift;
    if ( @_ ) {
        $self->{ no_create } = shift;
    }
    return $self->{ no_create };
}

1;

__END__



=head1 NAME

Net::OBEX::Packet::Request::SetPath - create OBEX protocol C<SetPath> request packets.

=head1 SYNOPSIS

    use Net::OBEX::Packet::Request::SetPath;

    my $pack= Net::OBEX::Packet::Request::SetPath->new(
        headers => [ $bunch, $of, $raw, $headers ],
    );

    my $setpath_packet = $pack->make;

    $pack->headers([]); # reset headers.
    $pack->do_up(1);    # set the "backup a level before applying name"
    $pack->no_create(0); # unset the "don't create" flag

    my $empty_abort = $aborts->make;

=head1 DESCRIPTION

B<WARNING!!! This module is in an early alpha stage. It is recommended
that you use it only for testing.>

The module provides means to create OBEX protocol C<SetPath>
(C<0x85>) packets.
It is used internally by L<Net::OBEX::Packet::Request> module and you
probably want to use that instead.

=head1 CONSTRUCTOR

=head2 new

    $pack = Net::OBEX::Packet::Request::SetPath->new;

    $pack2 = Net::OBEX::Packet::Request::SetPath->new(
        do_up     => 0,
        no_create => 1,
        constants => "\x00",
        headers   => [ $some, $raw, $headers ],
    );

Returns a Net::OBEX::Packet::Request::SetPath object, takes
several optional arguments which are as follows:

=head3 headers

    $pack2 = Net::OBEX::Packet::Request::SetPath->new(
        headers   => [ $some, $raw, $headers ],
    );

B<Optional>. Takes an arrayref as a value, elements of which are raw OBEX
packet headers. See L<Net::OBEX::Packet::Headers> if you want to create
those. B<Defaults to:> C<[]> (no headers)

=head3 do_up

    $pack2 = Net::OBEX::Packet::Request::SetPath->new( do_up => 1 );

B<Optional>. Indicates whether or not the I<backup a level before
applying name> flag bit should be set. B<Defaults to:> C<0>

=head3 no_create

    $pack2 = Net::OBEX::Packet::Request::SetPath->new( no_create => 0 );

B<Optional>. Indicates whether or not the I<don't create directory if it
does not exist, return an error instead> flag bit should be set.
B<Defaults to:> C<1>

=head3 constants

    $pack2 = Net::OBEX::Packet::Request::SetPath->new(
        constants => "\x00",
    );

B<Optional>. Takes a byte representing packet constants. Currently those
are reserved so you probably shouldn't be using this. B<Defaults to:>
C<"\x00"> (all bits set to zero)

=head1 METHODS

=head2 make

    my $raw_packet = $pack->make;

Takes no arguments, returns a raw OBEX packet ready to go down the wire.

=head2 raw

    my $raw_packet = $pack->raw;

Takes no arguments, must be called after C<make()> call, returns the
raw OBEX packet which was made with last C<make()> (i.e. the last
return value of C<make()>).

=head1 ACCESSORS/MUTATORS

=head2 headers

    my $headers_ref = $pack->headers;

    $pack->headers( [ $bunch, $of, $raw, $headers ] );

Returns an arrayref of currently set OBEX packet
headers. Takes one optional argument which is an arrayref, elements of
which are raw OBEX
packet headers. See L<Net::OBEX::Packet::Headers> if you want to create
those. If you want a packet with no headers use an empty arrayref
as an argument.

=head2 do_up

    my $old_do_up_flag = $pack->do_up;

    $pack->do_up( 1 );

Returns either true or false value indicating whether or not the
I<backup a level before applying name> flag bit is set. Takes one
optional argument which is either a true or false value indicating
whether or not the I<backup a level before applying name> flag bit
should be set in the next generated packet.

=head2 no_create

    my $old_no_create_flag = $pack->no_create;

    $pack->no_create(0);

Returns either true or false value indicating whether or not the
I<don't create directory if it does not exist, return an error instead>
flag bit is set. Takes one
optional argument which is either a true or false value indicating
whether or not the I<don't create directory if it
does not exist, return an error instead> flag bit
should be set in the next generated packet.

=head2 constants

    my $old_constants = $pack->constants;

    $pack->constants( "\x00" );

Returns a byte representing currently set packet "constants".
Takes a one byte value representing packet "constants" bit which will
be present in the next generated packets. Currently all constants
are reserved so you probably shouldn't be using this.

=head2 flags

    my $old_flags = $pack->flags;

    $pack->flags( pack 'B*', '11000000' );

Returns a byte representing currently set flags (that is the
C<do_up()> and C<no_create()> flags plus six more reserved bytes).
Takes one optional argument which is a byte representing packet "flags"
byte. Use the C<do_up()> and C<no_create()> methods to set the only
two non-reserved flags.

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