package TAEB::World::Tile::Altar;
use TAEB::OO;
use TAEB::Util qw/:colors display/;
extends 'TAEB::World::Tile';

has align => (
    is        => 'rw',
    isa       => 'TAEB::Type::Align',
    predicate => 'has_align',
);

sub debug_color {
    my $self = shift;

    return display(COLOR_RED)   if $self->align eq 'Cha';
    return display(COLOR_GREEN) if $self->align eq 'Neu';
    return display(COLOR_CYAN)  if $self->align eq 'Law';

    return display(COLOR_MAGENTA);
}

sub reblessed {
    my $self = shift;
    my ($old_class, $align) = @_;

    if ($align) {
        $self->align($align);
        return;
    }

    TAEB->enqueue_message(check => tile => $self);
}

sub farlooked {
    my $self = shift;
    my $msg  = shift;

    if ($msg =~ /altar.*(chaotic|neutral|lawful)/) {
        $self->align(ucfirst(substr($1, 0, 3)));
    }
}

around debug_line => sub {
    my $orig = shift;
    my $self = shift;
    my $line = $self->$orig(@_);

    $line .= " " . $self->align if $self->align;
    return $line;
};

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

