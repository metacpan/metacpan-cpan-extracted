# ----------------------------------------------------------------------------#
# Object::Registrar                                                           #
#                                                                             #
# Copyright (c) 2001-02 Arun Kumar U <u_arunkumar@yahoo.com>.                 #
# All rights reserved.                                                        #
#                                                                             #
# This program is free software; you can redistribute it and/or               #
# modify it under the same terms as Perl itself.                              #
# ----------------------------------------------------------------------------#

package Object::Registrar;

use Object::NotFoundException;
use Object::AlreadyBound;

use strict;
use vars qw($VERSION);

$VERSION = "0.01"; 

## Ultra safe Class Attribute(s) :-)
{
	my %ClassData =
	(
		'Instance' => undef,
		'Debug'    => 0,
	);
	
	foreach my $datum	(keys(%ClassData)) {
		no strict 'refs';
		*$datum = sub {
			use strict 'refs';
			my ($self, $newvalue) = @_;
			$ClassData{$datum} = $newvalue if @_ > 1;
			return($ClassData{$datum});
		};
	}
};

sub _newInstance
{
	my ($proto) = shift;
	my ($self, $class);
	
	$self = {};	
	$self->{'registry'} = undef;
	$class = ref($proto) || $proto;

	bless($self, $class);
	return $self;
}

sub new
{
	my ($self) = @_;
	
	my $instance = $self->Instance();
	if (!defined($instance)) { 
		$instance = $self->_newInstance();
		$self->Instance($instance);
	}
	return($instance);
}

sub _store
{
	my ($self, $name, $object) = @_;

	my $registrar = $self->getInstance();
	$registrar->{'registry'}->{$name} = $object;
}

sub _retrieve
{
	my ($self, $name) = @_;

	my $registrar = $self->getInstance();
	return $registrar->{'registry'}->{$name};
}

sub _destroy
{
	my ($self, $name) = @_;

	my $registrar = $self->getInstance();
	$registrar->{'registry'}->{$name} = undef;
	delete $registrar->{'registry'}->{$name};
}

sub exists
{
	my ($self, $name) = @_;

	my $registrar = $self->getInstance();
	if (exists($registrar->{'registry'}->{$name})) { return 1; }
	else { return 0; }
}

sub getContexts
{
	my ($self) = @_;

	my $registrar = $self->getInstance();
	return keys(%{$registrar->{'registry'}});
}

sub bind
{
	my ($self, $name, $object) = @_;

	if ($self->exists($name)) { 
		throw Object::AlreadyBound("Object already bound with the name \"$name\"\n");
	}
	else { $self->_store($name, $object); }
	print STDERR "Bound \"$name\" [$object] with Registrar\n" if ($self->Debug());
}

sub rebind
{
	my ($self, $name, $object) = @_;

	$self->_store($name, $object);
	print STDERR "Bound \"$name\" [$object] with Registrar\n" if ($self->Debug());
}

sub unbind
{
	my ($self, $name) = @_;
	
	$self->_destroy($name);
	print STDERR "Unbound \"$name\" from Registrar\n" if ($self->Debug());
}

sub resolve
{
	my ($self, $name) = @_;
	
	if (!$self->exists($name)) {
		throw Object::NotFoundException("Object \"$name\" not found\n");
	}

	my $object = $self->_retrieve($name);
	if (!$object) {
		throw Object::NotFoundException("Object \"$name\" not found\n");
	}
	return($object);
}

sub list
{
	my ($self, $pattern) = @_;
	my (%objhash);
	
	my @keys = $self->getContexts();
	foreach my $key (@keys) {
		if ($key =~ m/^${pattern}$/) {
			$objhash{$key} = $self->_retrieve($key); 
		}
	}
	return %objhash;
}

# Just to stop perl -cw from complaining 
sub getInstance;
sub register;
sub reregister;
sub unregister;

## Some useful method aliases
*getInstance = \&new;
*register    = \&bind;
*reregister  = \&rebind;
*unregister  = \&unbind;

1;

__END__;

=head1 NAME

Object::Registrar - A global registry of objects that can be resolved by names

=head1 SYNOPSIS

  use Object::Registrar;

  my $or = new Object::Registrar();

  $nm->bind('Test/Foo', new Foo());      ## or use register()
  $nm->bind('Test/Bar', new Bar());

  my $foo = $nm->resolve('Test/Foo');
  $nm->rebind('Test/Bar', $bar);         ## or use reregister()

  my %objhash = $or->list();
  my %objhash = $or->list('Test/*');

  my $bool = $or->exists('Test/Foo');

  $or->unbind('Test/Bar');               ## or use unregister()

  ## ----------------------------------- ##
  ## Typical usage with error handling   ##
  ## ----------------------------------- ##

  use Object::Registrar;
  use Error qw(:try);

  my $or = new Object::Registrar();
  try {
    $or->resolve('Null');
  }
  catch Object::NotFoundException with {
    my ($ex) = shift;
    print "Caught NotFoundException: $ex\n";
  };

=head1 DESCRIPTION

The C<Object::Registrar> implements is a global registry of objects. 
This module makes use of the Singleton Pattern to achieve the desired 
functionality. 

Using this module an application can register its Object instances 
in the Registrar with a unique name. Later on in the application these 
object instances can be retrieved / resolved by providing the unique name.

The names provided for identifying the Objects can be anything that
would be acceptable as a valid hash key in Perl.

For a detailed description of the Singleton Pattern, refer "Design Patterns", 
Gamma et al, Addison-Wesley, 1995, ISBN 0-201-63361-2. 

=head1 METHODS

=over 4

=item $nm->bind (NAME, OBJ)

Binds the object specified OBJ in the Registry with the name NAME. The
object can then be retrieved from the Registry by invoking the
resolve() method, passing the NAME as a parameter. 

This method raises the B<Object::AlreadyBound> exception if the
specified NAME already exists in the Registry.

=item $nm->rebind (NAME, OBJ)

Unlike bind() this method does not raise the B<Object::AlreadyBound> expection
but otherwise performs the same functions as bind(). Using this method
allows you to associate an object OBJ with a NAME that is already bound in 
the Registry.

=item $nm->unbind (NAME)

This method disassociates the mapping between the given name NAME and
its object from the Registry.

=item $nm->resolve (NAME)

This method retruns the object referred by the given name NAME.

This method raises the B<Object::NotFoundException> exception if the
specified NAME does not exist in the Registry or if the object 
referenced by the NAME is not defined.

=item $nm->exists (NAME)

Returns a boolean value indicating existence of the given name NAME in 
the Registry. 

=item $nm->list ([PATTERN])

This method returns a Perl hash containing all the names in the Registry
as keys in the hash. The objects referred by the names are stored as
values to the corresponding key in the hash. 

This method accepts any valid perl regular expression i.e PATTERN
to filter the keys that would be returned. If the PATTERN is left
undefined then all the names in the Registry are returned.

=item $nm->register (NAME, OBJ)

Alias for bind(). Works exactly the same as bind();

=item $nm->reregister (NAME, OBJ)

Alias for rebind(). Works exactly the same as rebind();

=item $nm->unregister (NAME)

Alias for unbind(). Works exactly the same as unbind();

=item $nm->Debug ([VAL])

This method turn ON verbosity if the VAL is TRUE and truns OFF 
verbosity if VAL is FALSE. If called without any parameters it 
returns the current value for the verbosity flag.

=back

=head1 STATIC INVOCATION

All the above methods can also be statically 
invoked. As illustrated here:

  Object::Registrar->bind('Test/Foo', new Foo());
  my $foo = Object::Registrar->resolve('Test/Foo');

  my %objhash = Object::Registrar->list('Widget/Labels*');

     ....
     ....

  Object::Registrar->unbind('Test/Bar'); 

=head1 EXCEPTIONS

=over 4

=item Object::NotFoundException

This exception is raised when a call to resolve() is not able to locate
an object with the given name in the Registry.

=item Object::AlreadyBound

This exception is raised when bind() or register() is called with 
a name that is already available in the Registry.

=back

=head1 PREREQUISITES

Error.pm - Error/exception handling in an OO-ish way

=head1 KNOWN BUGS

None. Well if they are B<KNOWN>, they will be fixed :-)

=head1 COPYRIGHT

Copyright (c) 2001 Arun Kumar U <u_arunkumar@yahoo.com>. All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Arun Kumar U <u_arunkumar@yahoo.com>

=head1 SEE ALSO

perl(1)

=cut

