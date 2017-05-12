package HashClass;

use base qw(Oryx::Class);

our $schema = {
    attributes => [{
        name => 'attrib1',
        type => 'String',
        size => '255',
    }],
    associations => [{
        role => 'assoc2',
        type => 'Hash',
        class => 'Class1',
    }],
};

1;

