use utf8;

package Net::EGTS::Packet::Response;
use namespace::autoclean;
use Mouse;
extends qw(Net::EGTS::Packet);

use Carp;
use List::MoreUtils     qw(natatime);

use Net::EGTS::Types;
use Net::EGTS::Codes;
use Net::EGTS::Util     qw(usize);

# Response Packet ID
has RPID        => is => 'rw', isa => 'USHORT';
# Processing Result
has PR          => is => 'rw', isa => 'BYTE';
# Service Data Record
has SDR         => is => 'rw', isa => 'Maybe[BINARY]';

after 'decode' => sub {
    my ($self) = @_;
    use bytes;

    die 'Packet not EGTS_PT_RESPONSE type'
        unless $self->PT == EGTS_PT_RESPONSE;

    return unless defined $self->SFRD;
    return unless length  $self->SFRD;

    my $bin = $self->SFRD;
    $self->RPID( $self->nip(\$bin => 'S') );
    $self->PR(   $self->nip(\$bin => 'C') );
    $self->SDR(  $self->nip(\$bin => 'a*' => length($bin)) );
};

before 'encode' => sub {
    my ($self) = @_;
    use bytes;

    die 'Packet not EGTS_PT_RESPONSE type'
        unless $self->PT == EGTS_PT_RESPONSE;

    my $bin = pack 'S C' => $self->RPID, $self->PR;
    $bin   .= pack 'a*'  => $self->SDR              if defined $self->SDR;

    $self->SFRD( $bin );
};

around BUILDARGS => sub {
    my $orig    = shift;
    my $class   = shift;
    return $class->$orig( @_, PT => EGTS_PT_RESPONSE );
};

augment as_debug => sub {
    my ($self) = @_;
    use bytes;

    my @bytes = ((unpack('B*', $self->SFRD)) =~ m{.{8}}g);

    my @str;
    push @str => sprintf('RPID:   %s %s',       splice @bytes, 0 => usize('S'));
    push @str => sprintf('PR:     %s',          splice @bytes, 0 => usize('C'));

    my $it = natatime 4, @bytes;
    my @chunks;
    while (my @vals = $it->()) {
        push @chunks, join(' ', @vals);
    }
    push @str => sprintf('SDR:    %s', join("\n        ", @chunks));

    return @str;
};

__PACKAGE__->meta->make_immutable();
