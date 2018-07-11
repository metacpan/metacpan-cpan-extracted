use utf8;

package Net::EGTS::SubRecord::Auth::ResultCode;
use Mouse;
extends qw(Net::EGTS::SubRecord);

use Carp;

use Net::EGTS::Util     qw(usize);
use Net::EGTS::Codes;

# Result Code
has RCD         => is => 'rw', isa => 'BYTE', default => EGTS_PC_OK;

after 'decode' => sub {
    my ($self) = @_;
    die 'SubRecord not EGTS_SR_RESULT_CODE type'
        unless $self->SRT == EGTS_SR_RESULT_CODE;

    my $bin = $self->SRD;
    $self->RCD( $self->nip(\$bin => 'C') );
};

before 'encode' => sub {
    my ($self) = @_;
    die 'SubRecord not EGTS_SR_RESULT_CODE type'
        unless $self->SRT == EGTS_SR_RESULT_CODE;

    $self->SRD( pack 'C' => $self->RCD );
};

around BUILDARGS => sub {
    my $orig    = shift;
    my $class   = shift;

    # simple scalar decoding support
    my $bin   = @_ % 2 ? shift : undef;
    my %opts  = @_;

    return $class->$orig( bin => $bin, %opts, SRT => EGTS_SR_RESULT_CODE )
        if $bin;
    return $class->$orig(              %opts, SRT => EGTS_SR_RESULT_CODE );
};

augment as_debug => sub {
    my ($self) = @_;
    use bytes;

    my @bytes = ((unpack('B*', $self->SRD)) =~ m{.{8}}g);

    my @str;
    push @str => sprintf('RCD:    %s',          splice @bytes, 0 => usize('C'));

    return @str;
};

__PACKAGE__->meta->make_immutable();
