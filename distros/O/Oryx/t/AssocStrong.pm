package AssocStrong;

use base qw(Oryx::Class);

our $schema = {
    attributes => [{
        name => "attrib1",
        type => "String",
        size => "255",
    }],
    associations => [{
        role => 'assoc_strong',
        type => 'Array',
        class => 'AssocWeak',
    }]
};

1;
