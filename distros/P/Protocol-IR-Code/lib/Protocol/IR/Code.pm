package Protocol::IR::Code;
use strict;
use warnings;

our $VERSION = '1.0';

sub new {
    my ($class, %args) = @_;
    return bless {
        protocol        => $args{protocol}        // 'UNKNOWN',
        bits            => $args{bits}            // 0,
        address         => $args{address}         // 0,
        subaddress      => $args{subaddress}      // -1,
        command         => $args{command}         // 0,
        data            => $args{data}            // undef,
        alias           => $args{alias}           // '',
        ditto_count     => $args{ditto_count}     // 0,
        send_count      => $args{send_count}      // 0,
        bypass_protocol => $args{bypass_protocol} // 0,
        timings         => $args{timings}         // undef,
        pronto          => $args{pronto}          // undef,
    }, $class;
}

# Accessors
sub protocol        { $_[0]->{protocol}        = $_[1] if @_ > 1; $_[0]->{protocol} }
sub bits            { $_[0]->{bits}            = $_[1] if @_ > 1; $_[0]->{bits} }
sub address         { $_[0]->{address}         = $_[1] if @_ > 1; $_[0]->{address} }
sub subaddress      { $_[0]->{subaddress}      = $_[1] if @_ > 1; $_[0]->{subaddress} }
sub command         { $_[0]->{command}         = $_[1] if @_ > 1; $_[0]->{command} }
sub data            { $_[0]->{data}            = $_[1] if @_ > 1; $_[0]->{data} }
sub alias           { $_[0]->{alias}           = $_[1] if @_ > 1; $_[0]->{alias} }
sub ditto_count     { $_[0]->{ditto_count}     = $_[1] if @_ > 1; $_[0]->{ditto_count} }
sub send_count      { $_[0]->{send_count}      = $_[1] if @_ > 1; $_[0]->{send_count} }
sub bypass_protocol { $_[0]->{bypass_protocol} = $_[1] if @_ > 1; $_[0]->{bypass_protocol} }
sub timings         { $_[0]->{timings}         = $_[1] if @_ > 1; $_[0]->{timings} }
sub pronto          { $_[0]->{pronto}          = $_[1] if @_ > 1; $_[0]->{pronto} }

sub to_irsend {
    my ($self) = @_;
    my %hash = (
        Protocol => $self->{protocol},
        Bits     => $self->{bits},
    );
    if (defined $self->{data}) {
        $hash{Data} = _data_hex($self->{data});
    }
    return \%hash;
}

# The display hex of a data word, padded to the whole bytes the value needs
# (minimum 4 digits), exactly as Tasmota prints Data: leading zeros are
# trimmed to an even digit count and the word is never truncated, so 36/48/72
# bit words keep every bit. Accepts a Math::BigInt for protocols whose frames
# exceed the native integer range (e.g. MWM, up to 144 bits).
sub _data_hex {
    my ($val) = @_;
    return '' unless defined $val;
    my $hex;
    if (ref $val && $val->can('as_hex')) {
        $hex = $val->as_hex;
        $hex =~ s/^0x//i;
    } else {
        $hex = sprintf("%X", $val);
    }
    $hex = uc $hex;
    my $digits = length $hex;
    my $width  = 4;
    $width = ($digits % 2) ? $digits + 1 : $digits if $digits > 4;
    return '0x' . ('0' x ($width - $digits)) . $hex;
}

# Reverse the bits within an 8-bit byte.
# Exported so protocol handlers can share it for cross-protocol conversion.
sub reverse_byte {
    my ($val) = @_;
    my $out = 0;
    for my $i (0 .. 7) {
        $out |= (($val >> $i) & 1) << (7 - $i);
    }
    return $out;
}

1;

=head1 NAME

Protocol::IR::Code - Intermediate representation of an IR remote control code

=head1 VERSION

version 1.0

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();
    my $code = $converter->import_code('NEC', '0x10EF00FF');

    print $code->protocol;    # NEC
    print $code->address;     # 16
    print $code->command;     # 0

    my $hash = $code->to_irsend;   # Tasmota IRSend JSON payload

=head1 DESCRIPTION

C<Protocol::IR::Code> is the unified intermediate representation used throughout the
Protocol::IR::Code distribution. Every protocol handler decodes into an C<Protocol::IR::Code>
object and every format exports from one, so a signal can be moved between
protocols and formats without loss of information.

The object is compatible with Tasmota's C<IRSend> JSON payload structure:
L<to_irsend|/"to_irsend"> returns a hash with C<Protocol>, C<Bits>, and
C<Data> keys. The C<data> value is expressed so that it matches Tasmota's
C<Data> field for the protocol.

=head1 ATTRIBUTES

All attributes are read-write accessors, e.g. C<< $code->alias('POWER') >>.
They are created by the L<Protocol::IR::Converter> registry and the protocol/format
handlers; you normally do not construct C<Protocol::IR::Code> objects directly.

=over 4

=item protocol

Protocol name (e.g. C<NEC>), or C<UNKNOWN> for undecoded timing data.

=item bits

Number of data bits in the frame.

=item address

Primary address (device) byte.

=item subaddress

Secondary address byte, or C<-1> when the protocol has none (JVC, SAMSUNG)
or when it equals the one's complement of the address (standard NEC frames).

=item command

Command (function) byte.

=item data

The raw transmitted value. Bit order matches the protocol's C<Data> field
in Tasmota (see the individual protocol modules).

=item alias

A human-readable button name, carried by CSV and wig round trips.

=item ditto_count

Number of repeat ("ditto") frames a wig should send after the first.

=item send_count

How many times the whole signal transmits per press (the wig's C<send_count>,
the Global Cache IR database's per-command repeat count).  Zero means the
source carried no repeat count, so a wig export omits C<send_count> and the
default single press is assumed.

=item bypass_protocol

Flag marking that a wig should bypass protocol-aware repeat behavior.

=item timings

When a signal is decoded from raw timing data (Pronto or Tasmota), the
individual mark/space timings are retained here so the capture can be
re-exported losslessly. C<undef> for codes built from decoded fields.

=item pronto

The original raw Pronto Hex payload of a signal no registered protocol
recognized, stashed verbatim so the code re-exports losslessly as a raw
(protocol C<UNKNOWN>, C<bypass_protocol> set) signal. C<undef> for codes
built from decoded fields.

=back

=head1 METHODS

=head2 to_irsend

    my $hash = $code->to_irsend;

Returns a hashref with C<Protocol>, C<Bits>, and (when known) C<Data> keys,
matching the structure of a Tasmota C<IRSend> JSON payload.

=head1 FUNCTIONS

=head2 reverse_byte

    my $reversed = Protocol::IR::Code::reverse_byte(0xE0);  # returns 0x07

Reverses the bits within an 8-bit byte.  Used by
L<Protocol::IR::Proto::SAMSUNG/as_necx2_params> and
L<Protocol::IR::Proto::NECX2/as_samsung_params> for cross-protocol
conversion between SAMSUNG and NECX2, where the Samsung address/command
bytes are the bit-reversal of the NECX2 device/function bytes.

This is an exported package function (not a method), callable as
C<< Protocol::IR::Code::reverse_byte($val) >>.

=head1 SUPPORT

Source code: L<https://github.com/bwarden/perl-protocol-ir>

Bug reports and feature requests: L<https://github.com/bwarden/perl-protocol-ir/issues>

=head1 AUTHOR

Brett T. Warden <bwarden@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Brett T. Warden

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License version 2.1 as
published by the Free Software Foundation.

=head1 TRADEMARK NOTICE

This project exists solely to enable interoperability with independently
purchased hardware. It is an independent community project: it is not
supplied by, authorized by, affiliated with, or endorsed by The Walt Disney
Company or any other rights holder. "Made With Magic", "Glow With The Show",
and all related names and marks are trademarks of their respective owners,
referenced here only to identify interoperable functionality.
