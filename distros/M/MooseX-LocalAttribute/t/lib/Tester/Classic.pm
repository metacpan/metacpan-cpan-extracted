package Tester::Classic;
use strict;
use warnings;

sub new {
    my ($class) = @_;

    return bless {
        hashref => { key => 'value' },
        string  => 'string',
    }, $class;
}

sub hashref {
    my $self = shift;

    $self->{hashref} = shift if @_ == 1;
    return $self->{hashref};
}

sub string {
    my $self = shift;

    $self->{string} = shift if @_ == 1;
    return $self->{string};
}

sub change_hashref {
    my ( $self, $key, $val ) = @_;

    $self->hashref->{$key} = $val;
}

1;
