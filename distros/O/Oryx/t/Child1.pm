package Child1;

use base qw(Parent1 Parent2);

our $schema = {
    attributes => [{
        name => 'child_attrib1',
        type => 'String',
        required => 1,
    }],
};

1;
