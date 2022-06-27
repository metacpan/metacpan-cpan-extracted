package Tester::ClassAccessor;
use strict;
use warnings;

use parent 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(hashref string));

sub new {
    my ($class) = @_;

    return bless {
        hashref => { key => 'value' },
        string  => 'string',
    }, $class;
}

sub change_hashref {
    my ( $self, $key, $val ) = @_;

    $self->hashref->{$key} = $val;
}

1;
