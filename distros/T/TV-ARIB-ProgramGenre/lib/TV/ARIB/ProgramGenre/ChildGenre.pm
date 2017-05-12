package TV::ARIB::ProgramGenre::ChildGenre;
use strict;
use warnings;
use utf8;
use Carp;
use Encode qw/decode_utf8 encode_utf8/;

# ABSTRACT
sub CHILD_GENRES {
    die;
}

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub get_child_genre_name {
    my ($self, $id) = @_;

    my $child_genre = $self->CHILD_GENRES->[$id];
    if (not defined $child_genre) {
        croak "No such a genre (ID: $id)";
    }

    return encode_utf8($child_genre);
}

sub get_child_genre_id {
    my ($self, $name) = @_;

    eval { $name = decode_utf8($name) };

    my $id = 0;
    for my $genre (@{$self->CHILD_GENRES}) {
        return $id if $genre eq $name;
        $id++;
    }

    croak encode_utf8("No such a child genre: $name");
}

1;

