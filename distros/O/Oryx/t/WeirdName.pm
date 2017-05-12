package WeirdName;

use base qw(Oryx::Class);

our $schema = {
    name => 'weirder_class_name',
    attributes => [{
        name => 'attrib1',
        type => 'String',
    }]
};

1;
