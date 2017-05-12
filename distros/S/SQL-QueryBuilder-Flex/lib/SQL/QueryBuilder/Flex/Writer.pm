package SQL::QueryBuilder::Flex::Writer;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    my $self = bless {
        _buffer => [],
        _params => [],
    }, $class;
    return $self;
}

sub clear {
    my ($self) = @_;
    $self->{_buffer} = [];
    $self->{_params} = [];
}

sub write {
    my ($self, $str, $indent) = @_;
    push @{ $self->{_buffer} }, [ $str, $indent || 0 ];
    return;
}

sub add_params {
    my ($self, @params) = @_;
    push @{ $self->{_params} }, @params;
    return;
}

sub get_params {
    my ($self) = @_;
    return wantarray ? @{ $self->{_params} } : $self->{_params};
}

sub to_sql {
    my ($self, $indent) = @_;

    return $indent
        ? join(
            "\n",
            map {
                join('', ("  ") x $_->[1], $_->[0])
            } @{ $self->{_buffer} }
        )
        : join(
            ' ',
            map {
                join(' ', $_->[0])
            } @{ $self->{_buffer} }
        )
    ;
}

1;
