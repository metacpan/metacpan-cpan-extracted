use utf8;

package Net::EGTS::Record;
use namespace::autoclean;
use Mouse;

use Carp;
use List::MoreUtils     qw(natatime);

use Net::EGTS::Util     qw(str2time time2new new2time usize dumper_bitstring);
use Net::EGTS::Types;

require  Net::EGTS::SubRecord;

our $RN    = 0;

=head1 NAME

Net::EGTS::Record - Record

=cut

# Record Length
has RL          =>
    is          => 'rw',
    isa         => 'USHORT',
    lazy        => 1,
    builder     => sub {
        my ($self) = @_;
        use bytes;
        return length($self->RD);
    },
;

# Record Number
has RN         =>
    is         => 'rw',
    isa        => 'USHORT',
    lazy       => 1,
    builder    => sub {
        my $rn = $RN;
        $RN = 0 unless ++$RN >= 0 && $RN <= 65535;
        return $rn;
    }
;


# Flags:
# Source Service On Device
has SSOD        => is => 'rw', isa => 'BIT1', default => 0x0;
# Recipient Service On Device
has RSOD        => is => 'rw', isa => 'BIT1', default => 0x0;
# Group
has GRP         => is => 'rw', isa => 'BIT1', default => 0x0;
# Record Processing Priority
has RPP         => is => 'rw', isa => 'BIT2', default => 0x00;
# Time Field Exists
has TMFE        =>
    is          => 'rw',
    isa         => 'BIT1',
    lazy        => 1,
    builder     => sub{ defined $_[0]->TM ? 0x1 : 0x0 },
;
# Event ID Field Exists
has EVFE        =>
    is          => 'rw',
    isa         => 'BIT1',
    lazy        => 1,
    builder     => sub{ defined $_[0]->EVID ? 0x1 : 0x0 },
;
# Object ID Field Exists
has OBFE        =>
    is          => 'rw',
    isa         => 'BIT1',
    lazy        => 1,
    builder     => sub{ defined $_[0]->OID ? 0x1 : 0x0 },
;

# Optional:
# Object Identifier
has OID         => is => 'rw', isa => 'Maybe[UINT]';
# Event Identifier
has EVID        => is => 'rw', isa => 'Maybe[UINT]';
# Time
has TM          => is => 'rw', isa => 'Maybe[UINT]';

# Source Service Type
has SST         => is => 'rw', isa => 'BYTE';
# Recipient Service Type
has RST         => is => 'rw', isa => 'BYTE';
# Record Data
has RD          =>
    is          => 'rw',
    isa         => 'BINARY',
    trigger     => sub {
         my ($self, $value, $old) = @_;
         die 'Record Data too short'    if length($value) < 3;
         die 'Record Data too long'     if length($value) > 65498;
    }
;

# Record binary
has bin         => is => 'rw', isa => 'Str',  default => '';

# Array of decoded subrecords
has subrecords     =>
    is          => 'rw',
    isa         => 'ArrayRef[Net::EGTS::SubRecord]',
    lazy        => 1,
    builder     => sub {
        my ($self) = @_;
        return [] unless defined $self->RD;
        return [] unless length  $self->RD;
        return Net::EGTS::SubRecord->decode_all( $self->RD );
    },
;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    # simple scalar decoding support
    my $bin   = @_ % 2 ? shift : undef;
    my %opts  = @_;

    # simple time support
    if( defined( my $time = delete $opts{time} ) ) {
        $opts{TM}   = time2new str2time $time;
        $opts{TMFE} = 1 if $opts{TM};
    }

    return $class->$orig( bin => $bin, %opts ) if $bin;
    return $class->$orig( %opts );
};
sub BUILD {
    my $self = shift;
    my $args = shift;
    $self->decode( \$self->bin ) if length $self->bin;
}

# Get chunk from binary and store it
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

=head2 encode

Build record as binary

=cut

sub encode {
    my ($self) = @_;
    use bytes;

    croak 'Source Service Type required'    unless defined $self->SST;
    croak 'Recipient Service Type required' unless defined $self->RST;
    croak 'Record Data required'            unless defined $self->RD;
    croak 'Wrong Record Length'             unless $self->RL >= 3 &&
                                                   $self->RL <= 65498;
    my $mask = 'S S B8';

    # Optional fields
    my @optional;
    if( $self->OBFE || $self->GRP ) {
        $mask = join ' ', $mask, 'L';
        push @optional, $self->OID;
    }
    if( $self->EVFE ) {
        $mask = join ' ', $mask, 'L';
        push @optional, $self->EVID;
    }
    if( $self->TMFE ) {
        $mask = join ' ', $mask, 'L';
        push @optional, $self->TM;
    }

    $mask = join ' ', $mask, 'C C a*';

    my $bin = pack $mask =>
        $self->RL, $self->RN,
        sprintf(
            '%b%b%b%02b%b%b%b',
            $self->SSOD, $self->RSOD, $self->GRP, $self->RPP, $self->TMFE,
            $self->EVFE, $self->OBFE,
        ),
        @optional,
        $self->SST, $self->RST, $self->RD
    ;

    $self->bin( $bin );
    return $bin;
}

=head2 decode \$bin

Decode binary I<$bin> into record object.
The binary stream will be truncated!

=cut

sub decode {
    my ($self, $bin) = @_;
    use bytes;

    $self->RL( $self->take($bin => 'S') );
    $self->RN( $self->take($bin => 'S') );

    my $flags = $self->take($bin => 'C');
    $self->SSOD( ($flags & 0b10000000) >> 7 );
    $self->RSOD( ($flags & 0b01000000) >> 6 );
    $self->GRP(  ($flags & 0b00100000) >> 5 );
    $self->RPP(  ($flags & 0b00011000) >> 3 );
    $self->TMFE( ($flags & 0b00000100) >> 2 );
    $self->EVFE( ($flags & 0b00000010) >> 1 );
    $self->OBFE( ($flags & 0b00000001)      );

    $self->OID(  $self->take($bin => 'L') ) if $self->OBFE || $self->GRP;
    $self->EVID( $self->take($bin => 'L') ) if $self->EVFE;
    $self->TM(   $self->take($bin => 'L') ) if $self->TMFE;

    $self->SST( $self->take($bin => 'C') );
    $self->RST( $self->take($bin => 'C') );

    $self->RD( $self->take($bin => 'a*' => $self->RL) );

    return $self;
}

=head2 decode_all \$bin

Parse all records from packet Service Frame Data

=cut

sub decode_all {
    my ($class, $bin) = @_;
    use bytes;

    my @result;
    while( my $length = length $bin ) {
        my $self = Net::EGTS::Record->new->decode( \$bin );
        die 'Something wrong in records decode' unless $self;

        push @result, $self;
    }

    return wantarray ? @result : \@result;
}

=head2 as_debug

Return human readable string

=cut

sub as_debug {
    my ($self) = @_;
    use bytes;

    my @bytes = ((unpack('B*', $self->bin)) =~ m{.{8}}g);

    my @str;
    push @str => sprintf('RL:     %s  %s',      splice @bytes, 0 => usize('S'));
    push @str => sprintf('RN:     %s  %s',      splice @bytes, 0 => usize('S'));
    push @str => sprintf('FLAGS:  %s',          splice @bytes, 0 => usize('C'));

    push @str => sprintf('OID:    %s %s %s %s', splice @bytes, 0 => usize('L'))
        if defined $self->OID;
    push @str => sprintf('EVID:   %s %s %s %s', splice @bytes, 0 => usize('L'))
        if defined $self->EVID;
    push @str => sprintf('TM:     %s %s %s %s', splice @bytes, 0 => usize('L'))
        if defined $self->TM;

    push @str => sprintf('SST:    %s',          splice @bytes, 0 => usize('C'));
    push @str => sprintf('RST:    %s',          splice @bytes, 0 => usize('C'));

    my $it = natatime 4, @bytes;
    my @chunks;
    while (my @vals = $it->()) {
        push @chunks, join(' ', @vals);
    }
    push @str => sprintf('RD:     %s', join("\n        ", @chunks));

    return join "\n", @str;
}

__PACKAGE__->meta->make_immutable();
