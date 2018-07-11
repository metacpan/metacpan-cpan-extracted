use utf8;

package Net::EGTS::Packet;
use namespace::autoclean;
use Mouse;

use Carp;
use List::MoreUtils     qw(natatime any);
use Module::Load        qw(load);

use Net::EGTS::Util     qw(crc8 crc16 usize dumper_bitstring);
use Net::EGTS::Types;
use Net::EGTS::Codes;

require Net::EGTS::Record;

# Global packet identifier
our $PID    = 0;

# Packet types and classes
our %TYPES = (
    EGTS_PT_RESPONSE,       'Net::EGTS::Packet::Response',
    EGTS_PT_APPDATA,        'Net::EGTS::Packet::Appdata',
    EGTS_PT_SIGNED_APPDATA, 'Net::EGTS::Packet::SignedAppdata',
);

# Protocol Version
has PRV         => is => 'rw', isa => 'BYTE', default => 0x01;
# Security Key ID
has SKID        => is => 'rw', isa => 'BYTE', default => 0;

# Flags:
# Prefix
has PRF         => is => 'rw', isa => 'BIT2', default => 0b00;
# Route
has RTE         => is => 'rw', isa => 'BIT1', default => 0b0;
# Encryption Algorithm
has ENA         => is => 'rw', isa => 'BIT2', default => 0b00;
# Compressed
has CMP         => is => 'rw', isa => 'BIT1', default => 0b0;
# Priority
has PRIORITY    => is => 'rw', isa => 'BIT2', default => 0b00;

# Header Length
has HL          =>
    is          => 'rw',
    isa         => 'BYTE',
    lazy        => 1,
    builder     => sub {
        my ($self) = @_;
        my $length = 11;
        $length += 2 if defined $self->PRA;
        $length += 2 if defined $self->RCA;
        $length += 1 if defined $self->TTL;
        return $length;
    },
;
# Header Encoding
has HE          => is => 'rw', isa => 'BYTE', default => 0x0;
# Frame Data Length
has FDL         =>
    is          => 'rw',
    isa         => 'USHORT',
    lazy        => 1,
    builder     => sub {
        my ($self) = @_;
        use bytes;
        return 0 unless defined $self->SFRD;
        return 0 unless length  $self->SFRD;
        return length $self->SFRD;
    },
;
# Packet Identifier
has PID         =>
    is          => 'rw',
    isa         => 'USHORT',
    lazy        => 1,
    builder     => sub {
        my $pid = $PID;
        $PID = 0 unless ++$PID >= 0 && $PID <= 65535;
        return $pid;
    }
;
# Packet Type
has PT          => is => 'rw', isa => 'BYTE';

# Optional (set if RTE enabled):
# Peer Address
has PRA         => is => 'rw', isa => 'Maybe[USHORT]';
# Recipient Address
has RCA         => is => 'rw', isa => 'Maybe[USHORT]';
# Time To Live
has TTL         => is => 'rw', isa => 'Maybe[BYTE]';

# Header Check Sum
has HCS         =>
    is          => 'rw',
    isa         => 'BYTE',
    lazy        => 1,
    builder     => sub {
        my ($self) = @_;
        use bytes;
        my $length = $self->HL - 1; # HL - HCS
        die 'Binary too short to get CRC8' if $length > length $self->bin;
        return crc8( substr( $self->bin, 0 => $length ) );
    },
;

# Service Frame Data
has SFRD        =>
    is          => 'rw',
    isa         => 'Maybe[BINARY]',
    default     => '',
    trigger     => sub {
         my ($self, $value, $old) = @_;
         die 'Service Frame Data too long'
            if defined($value) && length($value) > 65517;
    }
;
# Service Frame Data Check Sum
has SFRCS       =>
    is          => 'rw',
    isa         => 'Maybe[USHORT]',
    lazy        => 1,
    builder     => sub {
        my ($self) = @_;
        use bytes;
        die 'Binary too short to get CRC16' if $self->FDL > length $self->SFRD;
        return undef unless defined $self->SFRD;
        return undef unless length  $self->SFRD;
        return crc16( $self->SFRD );
    }
;

# Private:
# Packet binary
has bin         => is => 'rw', isa => 'Str',  default => '';

# Array of decoded records
has records     =>
    is          => 'rw',
    isa         => 'ArrayRef[Net::EGTS::Record]',
    lazy        => 1,
    builder     => sub {
        my ($self) = @_;
        return [] unless defined $self->SDR;
        return [] unless length  $self->SDR;
        return Net::EGTS::Record->decode_all( $self->SDR );
    },
;

#around BUILDARGS => sub {
#    my $orig  = shift;
#    my $class = shift;
#
#    # simple scalar decoding support
#    my $bin   = @_ % 2 ? shift : undef;
#    my %opts  = @_;
#
#    return $class->$orig(
#        bin     => $bin,
#        %opts
#    ) if $bin;
#    return $class->$orig( %opts );
#};
#sub BUILD {
#    my $self = shift;
#    my $args = shift;
#
#    $self->decode( \$self->bin ) if length $self->bin;
#    use Data::Dumper;
#    warn Dumper($self);
#}

# Store binary and count how mutch more bytes need
sub take {
    my ($self, $bin, $mask, $length) = @_;
    use bytes;

    $length //= usize($mask);
    confess "Can`t get chunk of length $length" if $length > length $$bin;

    my $chunk = substr $$bin, 0 => $length, '';
    $self->bin( $self->bin . $chunk );

    return unpack $mask => $chunk;
}

# Helper to get portion of data
sub nip {
    my ($self, $bin, $mask, $length) = @_;
    use bytes;

    $length //= usize($mask);
    confess "Can`t get chunk of length $length" if $length > length $$bin;

    my $chunk = substr $$bin, 0 => $length, '';
    return unpack $mask => $chunk;
}

=head2 stream \$bin

Parse incoming stream and creates packages from it.
If the data is not sufficient to create the package: returns the number
of data as many more as required.
The buffer is trimmed by the size of the created package.

Return:

=over

=item undef, $need

if decode in process and need more data

=item object

if the packet is fully decoded

=item error code

if there are any problems

=cut

sub stream {
    my ($class, $bin) = @_;
    use bytes;

    # Need first 10 bytes
    my $need = 10;
    return (undef, $need) if $need > length $$bin;

    # Packet size
    my $HL  = unpack 'C' => substr $$bin, 3, usize('C');
    my $FDL = unpack 'S' => substr $$bin, 5, usize('S');

    # Need full package size
    $need = $HL + $FDL + ($FDL ? 2 : 0);
    return (undef, $need) if $need > length $$bin;

    my $packet = substr $$bin, 0, $need, '';

    # Packet type
    my $PT  = unpack 'C' => substr $packet, 9, usize('C');

    # Create packet
    my $subclass = $TYPES{ $PT };
    load $subclass;
    return $subclass->new->decode( \$packet );
}

=head2 decode $bin

Decode binary stream I<$bin> into packet object.
Return:

=over

=item undef, $need

if decode in process and need more data

=item object

if the packet is fully decoded

=item error code

if there are any problems

=back

=cut

sub decode {
    my ($self, $bin) = @_;
    use bytes;

    $self->PRV( $self->take($bin => 'C') );
    $self->SKID($self->take($bin => 'C') );

    my $flags = $self->take($bin => 'C');
    $self->PRF(         ($flags & 0b11000000) >> 6 );
    $self->RTE(         ($flags & 0b00100000) >> 5 );
    $self->ENA(         ($flags & 0b00011000) >> 3 );
    $self->CMP(         ($flags & 0b00000100) >> 2 );
    $self->PRIORITY(    ($flags & 0b00000011)      );

    $self->HL(  $self->take($bin => 'C') );
    $self->HE(  $self->take($bin => 'C') );
    $self->FDL( $self->take($bin => 'S') );
    $self->PID( $self->take($bin => 'S') );
    $self->PT(  $self->take($bin => 'C') );

    return EGTS_PC_UNS_PROTOCOL     unless $self->PRV == 0x01;
    return EGTS_PC_INC_HEADERFORM   unless $self->HL  == 11 || $self->HL == 16;
    return EGTS_PC_UNS_PROTOCOL     unless $self->PRF == 0x00;

    if( $self->RTE ) {
        $self->PRA( $self->take($bin => 'S') );
        $self->RCA( $self->take($bin => 'S') );
        $self->TTL( $self->take($bin => 'C') );

        die 'RTE not supported';
    }

    # Header CRC8
    my $hsc = $self->take($bin => 'C');
    return EGTS_PC_HEADERCRC_ERROR unless $self->HCS == $hsc;

    # Complete package. No data.
    return $self unless $self->FDL;

    $self->SFRD( $self->take($bin => 'a*' => $self->FDL) );

    my $sfrcs = $self->take($bin => 'S');
    return EGTS_PC_DATACRC_ERROR unless $self->SFRCS == $sfrcs;

    unless( $self->ENA == 0x00 ) {
        warn 'Encryption not supported yet';
        return EGTS_PC_DECRYPT_ERROR;
    }

    unless( $self->CMP == 0x00 ) {
        warn 'Compression not supported yet';
        return EGTS_PC_INC_DATAFORM;
    }

    return $self;
}

=head2 encode

Build packet as binary

=cut

sub encode {
    my ($self) = @_;
    use bytes;

    croak 'Encryption not supported yet'    if $self->ENA;
    croak 'Compression not supported yet'   if $self->CMP;
    croak 'Packet Type required'            unless defined $self->PT;

    my $mask = 'C C B8 C C S S C';

    # Optional fields
    my @optional;
    if( $self->PRA || $self->RCA || $self->TTL ) {
        $mask .= ' S S C ';
        push @optional, $self->PRA;
        push @optional, $self->RCA;
        push @optional, $self->TTL;

        $self->RTE( 0x1 );
    }

    # Header Length
    $self->HL( 10 + ($self->RTE ? 5 : 0) + 1 );

    # Build base header
    my $bin =  pack $mask =>
        $self->PRV, $self->SKID,
        sprintf(
            '%02b%b%02b%b%02b',
            $self->PRF, $self->RTE, $self->ENA, $self->CMP, $self->PRIORITY,
        ),
        $self->HL, $self->HE, $self->FDL, $self->PID, $self->PT,
        @optional,
    ;

    # Header Check Sum
    $self->HCS( crc8 $bin );
    $bin .= pack 'C' => $self->HCS;

    # Service Frame Data
    $bin .= $self->SFRD if defined $self->SFRD;

    # Service Frame Data Check Sum
    if( $self->SFRD && $self->FDL ) {
        $bin .= pack 'S' => $self->SFRCS;
    }

    $self->bin( $bin );
    return $bin;
}

=head2 as_debug

Return human readable string

=cut

sub as_debug {
    my ($self) = @_;
    use bytes;

    my @bytes = ((unpack('B*', $self->bin)) =~ m{.{8}}g);

    my @str;
    push @str => sprintf('PRV:    %s',      splice @bytes, 0 => usize('C'));
    push @str => sprintf('SKID:   %s',      splice @bytes, 0 => usize('C'));
    push @str => sprintf('FLAGS:  %s',      splice @bytes, 0 => usize('C'));
    push @str => sprintf('HL:     %s',      splice @bytes, 0 => usize('C'));
    push @str => sprintf('HE:     %s',      splice @bytes, 0 => usize('C'));
    push @str => sprintf('FDL:    %s %s',   splice @bytes, 0 => usize('S'));
    push @str => sprintf('PID:    %s %s',   splice @bytes, 0 => usize('S'));
    push @str => sprintf('PT:     %s',      splice @bytes, 0 => usize('C'));

    push @str => sprintf('PRA:    %s %s',   splice @bytes, 0 => usize('S'))
        if defined $self->PRA;
    push @str => sprintf('RCA:    %s %s',   splice @bytes, 0 => usize('S'))
        if defined $self->RCA;
    push @str => sprintf('TTL:    %s',      splice @bytes, 0 => usize('C'))
        if defined $self->TTL;

    push @str => sprintf('HCS:    %s',      splice @bytes, 0 => usize('C'));

    if( @bytes ) {

        if( my @qualify = inner() ) {
            splice @bytes, 0 => -2;
            push @str => sprintf('SFRD =>');
            push @str, @qualify;
            push @str => sprintf('<======');
        } else {
            my $it = natatime 4, splice @bytes, 0 => -2;
            my @chunks;
            while (my @vals = $it->()) {
                push @chunks, join(' ', @vals);
            }
            push @str => sprintf('SFRD:   %s', join("\n        ", @chunks));
        }

        push @str => sprintf('SFRCS:  %s %s', splice @bytes, 0 => 2);
    }

    push @str, sprintf '(Data %d bytes. Total %d bytes.)',
        $self->FDL,
        length $self->bin
    ;

    return join "\n", @str;
}

__PACKAGE__->meta->make_immutable();
