package Sort::strverscmp::StringIterator;

use Carp qw(croak);
use v5.10;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $string = shift;

    unless ($string) {
        croak 'invalid string';
    }

    my $o = {};
    $o->{pos} = 0;
    $o->{string} = $string;
    $o->{len} = length($string);

    return bless $o, $class;
}

sub pos {
    my $self = shift;
    return $self->{pos};
}

sub string {
    my $self = shift;
    return $self->{string};
}

sub len {
    my $self = shift;
    return $self->{len};
}

sub head {
    my $self = shift;
    if ($self->pos >= $self->len) {
        return;
    } else {
        return substr($self->string, $self->pos, 1);
    }
}

sub tail {
    my $self = shift;
    return substr($self->string, $self->pos + 1);
}

sub tail_len {
    my $self = shift;
    return ($self->len - $self->pos);
}

sub advance {
    my $self = shift;
    $self->{pos}++;
}

sub next {
    my $self = shift;
    my $head = $self->head();
    $self->advance();
    return $head;
}

1;
