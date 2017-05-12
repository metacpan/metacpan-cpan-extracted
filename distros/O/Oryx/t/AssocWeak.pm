package AssocWeak;

use base qw(Oryx::Class);

our $schema = {
    attributes => [{
        name => "attrib1",
        type => "String",
        size => "255",
    }],
    associations => [{
        role => 'assoc_weak',
        type => 'Reference',
        class => 'AssocStrong',
        is_weak => 1,
    }]
};

1;
