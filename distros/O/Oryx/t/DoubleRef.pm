package DoubleRef;

use base qw( Oryx::Class );

our $schema = {
    attributes => [ {
        name => 'attrib1',
        type => 'String',
    } ],
    associations => [ {
        role => 'first_ref',
        class => 'Class2',
        type => 'Reference',
    }, {
        role => 'second_ref',
        class => 'Class2',
        type => 'Reference',
    } ],
};

1;
