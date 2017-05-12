package Persistence::Attribute;

use strict;
use warnings;

use Abstract::Meta::Class ':all';

use vars qw($VERSION);
use Carp 'confess';

$VERSION = 0.04;

abstract_class;


=head1 NAME

Persistence::Attribute - Abstract class for MOP attribute object.

=cut

=head1 SYNOPSIS

    package Employee;
    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';

    my $orm = entity 'emp';
    $orm->set_mop_attribute_adapter('Persistence::Attribute::MooseAdapter');
    column empno => has('$.no') ;
    column ename => has('$.name');


=head1 DESCRIPTION

Interface to MOP attribute object adapters.

=head1 EXPORT

None.

=head2 ATTRIBUES

=over

=item attribute

Wraps MOP atrribute.

=cut

has '$.attribute';


=item column_name

Column name.

=cut

has '$.column_name';


=back

=head2 METHODS

=over

=item name

Attribute name.

=cut

abstract 'name';


=item accessor

Accessor name - name of the method that returns value of the attribute.

    my $accessor = $attribute->accessor;
    my $value = $obj->$accessor;

=cut

abstract 'accessor';


=item mutator

Mutator name - name of the method that sets value of the attribute.

    my $accessor = $attribute->mutator;
    $obj->$mutator($value);

=cut

abstract 'mutator';

=item storage_key

Attribute storage key.

If this option is set and object_creation_method is set to 'bless'
then a new object creation will use bless method

    bless { map {($_->storage_key,  $args{$_->name})} @attributes}, $class

otherwise new method will be used.

    $class->new(map {($_->name,  $args{$_->name})} @attributes);

=cut

abstract 'storage_key';


=item associated_class

Name of the associated class.

For isntance if you have relationship bettwen My::Employee object and My::Dept
then associated_class will be My::Dept

=cut

abstract 'associated_class';


=item class_name

Class to whom the attribute belongs.

=cut

abstract 'class_name';


=item get_value

Returns value form object without triggering any events.
Takes object as parameter.

=cut

abstract 'get_value';



=item set_value

Sets object value without triggering any events.
Takes object, value as parameter.

=cut

abstract 'set_value';


=item has_value

Returns true there is value, false otherwise.
Takes object name as parameter.

=cut

abstract 'has_value';


=item find_attribute

Returns attribute definition.
Takes attribute name as parameter.

=cut

abstract 'find_attribute';


=item create_meta_attribute

Retuns a new persisitence attribute object.

This method provides support for plain classes, and xml metadata.
If the find attribute method can't find attribute for class then
this method should be able to create a new one ad hoc.
Takes hash ref with meta attriubtes properties, class name, column name.

=cut

abstract 'create_meta_attribute';


=item install_fetch_interceptor

This method should instal lazy fetch decorator.
It takes callback as parameters (code ref)
This code ref takes $object referece and $value of the attribute.

=cut

abstract 'install_fetch_interceptor';


1;

__END__

=back

=head1 COPYRIGHT AND LICENSE

The Persistence::Attribute module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas,adrian@webapp.strefa.pl

=cut
