use utf8;

package Net::EGTS::Packet::Appdata;
use namespace::autoclean;
use Mouse;
extends qw(Net::EGTS::Packet);

use Carp;
use List::MoreUtils     qw(natatime);

use Net::EGTS::Types;
use Net::EGTS::Codes;
use Net::EGTS::Util     qw(usize);

# Service Data Record
has SDR         => is => 'rw', isa => 'Maybe[BINARY]';

after 'decode' => sub {
    my ($self) = @_;
    die 'Packet not EGTS_PT_APPDATA type'
        unless $self->PT == EGTS_PT_APPDATA;

    $self->SDR( $self->SFRD );
};

before 'encode' => sub {
    my ($self) = @_;
    die 'Packet not EGTS_PT_APPDATA type'
        unless $self->PT == EGTS_PT_APPDATA;

    $self->SFRD( $self->SDR );
};

around BUILDARGS => sub {
    my $orig    = shift;
    my $class   = shift;
    return $class->$orig( @_, PT => EGTS_PT_APPDATA );
};

augment as_debug => sub {
    my ($self) = @_;
    use bytes;

    my @bytes = ((unpack('B*', $self->SFRD)) =~ m{.{8}}g);

    my @str;

    my $it = natatime 4, @bytes;
    my @chunks;
    while (my @vals = $it->()) {
        push @chunks, join(' ', @vals);
    }
    push @str => sprintf('SDR:    %s', join("\n        ", @chunks));

    return @str;
};

__PACKAGE__->meta->make_immutable();
