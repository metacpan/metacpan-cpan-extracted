package Persistence::Attribute::AMCAdapter;

use strict;
use warnings;

use vars qw($VERSION);

use Abstract::Meta::Class ':all';
use Persistence::Attribute':all';

use base qw(Persistence::Attribute);
use Carp 'confess';

$VERSION = 0.01;

=head1 NAME

Persistence::Attribute::AMCAdapter - Adapter to Abstract::Meta::Class meta object protocol.

=head1 CLASS HIERARCHY

 Persistence::Attribute
    |
    +----Persistence::Attribute::AMCAdapter

=head1 SYNOPSIS

    package Employee;

    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';

    my $orm = entity 'emp';
    $orm->set_mop_attribute_adapter('Persistence::Attribute::AMCAdapter');
    
    column empno => has('$.no') ;
    column ename => has('$.name');


=head1 DESCRIPTION

Interface to MOP attribute object adapters.

=head1 EXPORT

None.

=head2 ATTRIBUES

=over

=item object_creation_method

Returns object creation method.
Allowed values: bless or new

=cut

has '$.object_creation_method' => (
    default => 'bless',
    on_change => sub {
        my ($self, $attribute, $scope, $value) = @_;
        confess "invalid value for " . __PACKAGE__ . "::object_creation_method - allowed values(bless | new)"
            if $$value ne 'bless' && $$value ne 'new' 
    }
);


=item attribute

Any MOP atrribute.

=cut

has '$.attribute' => (associated_class => 'Abstract::Meta::Attribute');


=back

=head2 METHODS

=over

=item name

Attribute name.

=cut

sub name {
    my ($self) = @_;
    $self->attribute->name;
}


=item accessor

Accessor name - name of the method that returns value of the attribute.

    my $accessor = $attribute->accessor;
    my $value = $obj->$accessor;

=cut

sub accessor {
    my ($self) = @_;
    $self->attribute->accessor;
}


=item mutator

Accessor name - name of the method that sets value of the attribute.

=cut

sub mutator {
    my ($self) = @_;
    $self->attribute->mutator;
}


=item storage_key

Attribute storage key.

If this option is set and object_creation_method is set to 'bless'
then a new object creation will use bless method

    bless { map {($_->storage_key,  $args{$_->name})} @attributes}, $class

otherwise new method will be used.

    $class->new(map {($_->name,  $args{$_->name})} @attributes);

=cut

sub storage_key {
    my ($self) = @_;
    $self->attribute->storage_key;
}


=item associated_class

Name of the associated class.

For isntance if you have relationship bettwen My::Employee object and My::Dept
then associated_class will be My::Dept

=cut

sub associated_class {
    my ($self) = @_;
    $self->attribute->associated_class;
}


=item class_name

Class to whom the attribute belongs.

=cut

sub class_name {
    my ($self) = @_;
    $self->attribute->class;
}



=item get_value

Returns value form object without triggering any events.
Takes object as parameter.

=cut

sub get_value {
    my ($self, $object) = @_;
    $self->attribute->get_value($object);
}



=item set_value

Sets object value without triggering any events.
Takes object, value as parameter.

=cut

sub set_value {
    my ($self, $object, $value) = @_;
    $self->attribute->set_value($object, $value);
}


=item has_value

Returns true if object has value for the attribute.

=cut

sub has_value {
    my ($self, $object) = @_;
    my $attribute = $self->attribute;
    my $method = $object->can("has_" . $attribute->accessor);
    $method ? $method->($object) : $self->get_value($object);
}


=item find_attribute

Returns attribute
Takes class name attribute name.


=cut

sub find_attribute {
    my ($clazz, $class, $attribute_name) = @_;
    my $meta_class = Abstract::Meta::Class::meta_class($class);
    $meta_class->attribute($attribute_name);
}


=item create_meta_attribute

Return a new persisitence attribute object

=cut

sub create_meta_attribute {
    my ($clazz, $meta_attribute, $class, $column_name) = @_;
    my $meta_class = Abstract::Meta::Class::meta_class($class);
    my $name = $meta_attribute->{name};
    $name = '$.' . $name unless ($name =~ m/[\$\@\%]\./);
    my %args = (storage_key => $meta_attribute->{name}, %$meta_attribute, name => $name, class => $class);
   $clazz->new(attribute => $meta_class->attribute_class->new(%args), column_name => $column_name);
}


=item install_fetch_interceptor

=cut


sub install_fetch_interceptor {
    my ($self, $code_ref) = @_;
    my $attribute  = $self->attribute;
    $attribute->set_on_read(
        sub {
            my ($this, $attribute, $scope, $index) = @_;
            my $values = $attribute->get_value($this);
            $values = $code_ref->($this, $values);
            if ($scope eq 'accessor') {
                 return $values;
            } else {
                 my $type = ref $values;
                 return $type eq 'HASH' ? $values->{$index} : ($type eq  'ARRAY' ? $values->[$index] : $values);
            }
        }
    );
}

1;

__END__

=back

=head1 COPYRIGHT AND LICENSE

The Persistence::ORM::Attribute module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas,adrian@webapp.strefa.pl

=cut
