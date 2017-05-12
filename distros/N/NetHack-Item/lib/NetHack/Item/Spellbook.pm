package NetHack::Item::Spellbook;
{
  $NetHack::Item::Spellbook::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item';

use constant type => "spellbook";

has difficult_for_level => (
    is  => 'rw',
    isa => 'Int',
);

has difficult_for_int => (
    is  => 'rw',
    isa => 'Int',
);

sub spell {
    my $self = shift;

    return unless $self->has_identity;
    return unless $self->identity =~ m{^spellbook of (.*)$};
    return if $1 eq "blank paper";
    return $1;
}

sub did_blank {
    my $self = shift;

    # convert to blank
    $self->_clear_tracker;
    $self->appearance("plain spellbook");
    $self->identity("spellbook of blank paper");
}

__PACKAGE__->meta->install_spoilers(qw/ink level time emergency role skill direction/);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

