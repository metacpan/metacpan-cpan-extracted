use utf8;

package Net::EGTS::SubRecord::Auth::DispatcherIdentity;
use Mouse;
extends qw(Net::EGTS::SubRecord);

use Carp;
use List::MoreUtils     qw(natatime);
use Encode              qw();

use Net::EGTS::Util     qw(usize dumper_bitstring);
use Net::EGTS::Codes;

# Dispatcher Type
has DT          => is => 'rw', isa => 'BYTE', default => 0;
# Dispatcher ID
has DID         => is => 'rw', isa => 'UINT';
# Description
has DSCR        =>
    is          => 'rw',
    isa         => 'Maybe[STRING]',
    trigger     => sub {
        my ($self, $value, $old) = @_;
        use bytes;
        die 'Description too long' if defined($value) && length($value) > 255;
    }
;

after 'decode' => sub {
    my ($self) = @_;
    die 'SubRecord not EGTS_SR_DISPATCHER_IDENTITY type'
        unless $self->SRT == EGTS_SR_DISPATCHER_IDENTITY;

    my $bin = $self->SRD;
    $self->DT(   $self->nip(\$bin => 'C') );
    $self->DID(  $self->nip(\$bin => 'L') );
    $self->DSCR( $self->nip(\$bin => 'a*' => length($bin)) );
};

before 'encode' => sub {
    my ($self) = @_;
    die 'SubRecord not EGTS_SR_DISPATCHER_IDENTITY type'
        unless $self->SRT == EGTS_SR_DISPATCHER_IDENTITY;

    my $bin = pack 'C L' => $self->DT, $self->DID;
    $bin   .= pack 'a*'  => $self->DSCR             if defined $self->DSCR;

    $self->SRD( $bin );
};

around BUILDARGS => sub {
    my $orig    = shift;
    my $class   = shift;

    # simple scalar decoding support
    my $bin   = @_ % 2 ? shift : undef;
    my %opts  = @_;

    # Description is CP-1251
    $opts{DSCR} = Encode::encode('CP1251', $opts{DSCR}) if defined $opts{DSCR};

    return $class->$orig( bin => $bin, %opts, SRT => EGTS_SR_DISPATCHER_IDENTITY)
        if $bin;
    return $class->$orig(              %opts, SRT => EGTS_SR_DISPATCHER_IDENTITY);
};

augment as_debug => sub {
    my ($self) = @_;
    use bytes;

    my @bytes = ((unpack('B*', $self->SRD)) =~ m{.{8}}g);

    my @str;
    push @str => sprintf('DT:     %s',          splice @bytes, 0 => usize('C'));
    push @str => sprintf('DID:    %s %s %s %s', splice @bytes, 0 => usize('L'));

    my $it = natatime 4, @bytes;
    my @chunks;
    while (my @vals = $it->()) {
        push @chunks, join(' ', @vals);
    }
    push @str => sprintf('DSCR:   %s', join("\n        ", @chunks));

    return @str;
};

__PACKAGE__->meta->make_immutable();
