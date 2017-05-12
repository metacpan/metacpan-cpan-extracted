package Foo::Domain;

use Moose;
extends 'SimpleDB::Class::Item';

__PACKAGE__->set_domain_name('foo_domain');
__PACKAGE__->add_attributes(
    color           =>{isa=>'Str'}, 
    size            =>{isa=>'Str',
        trigger=>sub {
            my ($self, $new, $old) = @_;
            $self->size_formatted(ucfirst($new));
        },
    }, 
    size_formatted  =>{isa=>'Str' },
    parentId        =>{isa=>'Str'}, 
    quantity        =>{isa=>'Int'},
    properties      =>{isa=>'HashRef'},
    start_date      =>{isa=>'DateTime'},
    notes           =>{isa=>'MediumStr'},
    components      =>{isa=>'ArrayRefOfStr'},
    );
__PACKAGE__->has_many('children', 'Foo::Child', 'domainId', mate=>'domain', consistent=>1); # consistent because we run tests in real time
__PACKAGE__->belongs_to('parent', 'Foo::Parent', 'parentId', consistent=>1);


1;

