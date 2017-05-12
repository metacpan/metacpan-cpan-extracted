package AssocClass;

use base qw(Oryx::Class);

our $schema = {
    attributes => [{
        name => "attrib1",
        type => "String",
        size => "255",
    }],
    associations => [{
        role => 'assoc1',
        type => 'Array',
        class => 'Class1',
        constraint => 'Composition',
    },{
        role => 'assoc2',
        type => 'Reference',
        class => 'Class2',
    }]
};

1;
