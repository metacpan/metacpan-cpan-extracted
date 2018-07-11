use utf8;

package Net::EGTS::SubRecord;
use namespace::autoclean;
use Mouse;

use Carp;
use List::MoreUtils     qw(natatime);
use Module::Load        qw(load);

use Net::EGTS::Codes;
use Net::EGTS::Util     qw(usize);
use Net::EGTS::Types;

=head1 NAME

Net::EGTS::SubRecord - SubRecord common part

=cut

# Packet types and classes
our %TYPES = (
    EGTS_SR_RECORD_RESPONSE,        'Net::EGTS::SubRecord::Auth::RecordResponse',
    EGTS_SR_DISPATCHER_IDENTITY,    'Net::EGTS::SubRecord::Auth::DispatcherIdentity',
    EGTS_SR_RESULT_CODE,            'Net::EGTS::SubRecord::Auth::ResultCode',
    EGTS_SR_POS_DATA,               'Net::EGTS::SubRecord::Teledata::PosData',
);

# Subrecord Туре
has SRT         => is => 'rw', isa => 'BYTE';
# Subrecord Length
has SRL          =>
    is          => 'rw',
    isa         => 'USHORT',
    lazy        => 1,
    builder     => sub {
        my ($self) = @_;
        use bytes;
        return length($self->SRD);
    },
;
# Subrecord Data
has SRD         =>
    is          => 'rw',
    isa         => 'Maybe[BINARY]',
    trigger     => sub {
         my ($self, $value, $old) = @_;
         die 'Subrecord Data too long'  if length($value) > 65495;
    }
;

# SubRecord binary
has bin         => is => 'rw', isa => 'Str',  default => '';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    # simple scalar decoding support
    my $bin   = @_ % 2 ? shift : undef;
    my %opts  = @_;

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

Build subrecord as binary

=cut

sub encode {
    my ($self) = @_;
    use bytes;

    croak 'Subrecord Туре required'     unless defined $self->SRT;
    croak 'Subrecord Data required'     unless defined $self->SRD;
    croak 'Subrecord Length roo big'    unless $self->SRL <= 65495;

    my $bin = pack 'C S a*' => $self->SRT, $self->SRL, $self->SRD;
    $self->bin( $bin );
    return $bin;
}

=head2 decode \$bin

Decode binary I<$bin> into subrecord object.
The binary stream will be truncated!

=cut

sub decode {
    my ($self, $bin) = @_;
    use bytes;

    $self->SRT( $self->take($bin => 'C') );
    $self->SRL( $self->take($bin => 'S') );
    $self->SRD( $self->take($bin => 'a*' => $self->SRL) );

    return $self;
}

=head2 decode_all \$bin

Parse all subrecords from record Record Data

=cut

sub decode_all {
    my ($class, $bin) = @_;
    use bytes;

    my @result;
    while( my $length = length $bin ) {
        my $type = unpack 'C' => substr $bin, 0 => usize('C');

        my $subclass = $TYPES{ $type };
        load $subclass;

        my $self = $subclass->new->decode( \$bin );
        die 'Something wrong in subrecords decode' unless $self;

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
    push @str => sprintf('SRT:    %s',          splice @bytes, 0 => usize('C'));
    push @str => sprintf('SRL:    %s  %s',      splice @bytes, 0 => usize('S'));

    if( @bytes ) {
        if( my @qualify = inner() ) {
            push @str => sprintf('SRD  =>');
            push @str, @qualify;
            push @str => sprintf('<======');
        } else {
            my $it = natatime 4, @bytes;
            my @chunks;
            while (my @vals = $it->()) {
                push @chunks, join(' ', @vals);
            }
            push @str => sprintf('SRD:    %s', join("\n        ", @chunks));
        }
    }

    return join "\n", @str;
}

__PACKAGE__->meta->make_immutable();
