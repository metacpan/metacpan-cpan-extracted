package ObjectDB::Iterator;

use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{walker} = $params{walker};

    return $self;
}

sub next {
    my $self = shift;

    return $self->{walker}->($self);
}

1;
