package Tester::UtilH2O;
use strict;
use warnings;
use Util::H2O;

sub new {
    return h2o -meth => {
        hashref        => { key => 'value' },
        string         => 'string',
        change_hashref => sub {
            my ( $self, $key, $val ) = @_;

            $self->hashref->{$key} = $val;
        },
    };
}

1;
