package Parent1;

use base qw(Oryx::Class);

our $schema = {
    attributes => [{
        name => 'parent1_attrib',
        type => 'String',
    }],
};

1;
