use utf8;

package Net::EGTS::Packet::SignedAppdata;
use namespace::autoclean;
use Mouse;
extends qw(Net::EGTS::Packet);

use Carp;
use List::MoreUtils     qw(natatime);

use Net::EGTS::Types;
use Net::EGTS::Codes;
use Net::EGTS::Util     qw(usize);

# Signature Length
has SIGL        => is => 'rw', isa => 'SHORT', default => 0;
# Signature Data
has SIGD        => is => 'rw', isa => 'Maybe[BINARY]';
# Service Data Record
has SDR         => is => 'rw', isa => 'Maybe[BINARY]';

after 'decode' => sub {
    my ($self) = @_;
    die 'Packet not EGTS_PT_SIGNED_APPDATA type'
        unless $self->PT == EGTS_PT_SIGNED_APPDATA;

    return unless defined $self->SFRD;
    return unless length  $self->SFRD;

    my $bin = $self->SFRD;
    $self->SIGL( $self->nip(\$bin => 'S') );
    $self->SIGD( $self->nip(\$bin => 'a*' => $self->SIGL ) );
    $self->SDR(  $self->nip(\$bin => 'a*' => length($bin)) );
};

before 'encode' => sub {
    my ($self) = @_;
    die 'Packet not EGTS_PT_SIGNED_APPDATA type'
        unless $self->PT == EGTS_PT_SIGNED_APPDATA;

    my $bin = pack 'S'   => $self->SIGL;
    $bin   .= pack 'a*'  => $self->SIGD     if defined $self->SIGD;
    $bin   .= pack 'a*'  => $self->SDR      if defined $self->SDR;

    $self->SFRD( $bin );
};

around BUILDARGS => sub {
    my $orig    = shift;
    my $class   = shift;
    return $class->$orig( @_, PT => EGTS_PT_SIGNED_APPDATA );
};

augment as_debug => sub {
    my ($self) = @_;
    use bytes;

    my @bytes = ((unpack('B*', $self->SFRD)) =~ m{.{8}}g);

    my @str;
    push @str => sprintf('SIGL:    %s %s',  splice @bytes, 0 => usize('S'));

    my $it1 = natatime 4, splice @bytes, 0 => $self->SIGL;
    my @chunks1;
    while (my @vals = $it1->()) {
        push @chunks1, join(' ', @vals);
    }
    push @str => sprintf('SIGD:    %s', join("\n        ", @chunks1));

    my $it2 = natatime 4, @bytes;
    my @chunks2;
    while (my @vals = $it2->()) {
        push @chunks2, join(' ', @vals);
    }
    push @str => sprintf('SDR:    %s', join("\n        ", @chunks2));

    return @str;
};

__PACKAGE__->meta->make_immutable();
