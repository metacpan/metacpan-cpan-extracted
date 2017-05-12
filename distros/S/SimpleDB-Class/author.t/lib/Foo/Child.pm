package Foo::Child;

use Moose;
extends 'SimpleDB::Class::Item';

__PACKAGE__->set_domain_name('foo_child');
__PACKAGE__->add_attributes(
    domainId=>{isa=>'Str'},
    class   =>{isa=>'Str'},
);
__PACKAGE__->belongs_to('domain', 'Foo::Domain', 'domainId',consistent=>1); # consistent because we run tests in real time
__PACKAGE__->recast_using('class');

1;

