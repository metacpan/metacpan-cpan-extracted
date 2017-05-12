package ArrayClass;

use base qw(Oryx::Class);

our $schema = {
    attributes => [{
        name => 'attrib',
        type => 'String',
    }],
    associations => [{
        role  => 'array1',
        class => 'Class1',
        type  => 'Array',
    },{
        role  => 'array2',
        class => 'Class2',
        type  => 'Array',
    }],
};

1;

