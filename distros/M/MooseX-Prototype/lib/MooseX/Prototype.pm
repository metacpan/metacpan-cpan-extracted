use 5.008;
use strict;
use warnings;

use Moose                  2.00 ();
use Data::OptList          0    ();
use Sub::Exporter          0    ();

my $serial = 0;
my $serial_name = sub {
	sprintf('MooseX::Prototype::__ANON__::%04d', ++$serial);
};

my $mk_attribute = sub {
	my ($name, $rw) = @_;
	Moose::Meta::Attribute::->new($name, is => ($rw||'rw'), isa => 'Any');
};

my $cloned_attributes = sub {
	return [
		map {
			my $attr  = $_;
			my @clone = ();
			if ($attr->has_value($_[0]))
			{
				my $value = $attr->get_value($_[0]);
				@clone = ( default => sub{$value} );
			}
			$attr->clone(@clone);
		} $_[0]->meta->get_all_attributes
	]
};

BEGIN {
	package MooseX::Prototype;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	$INC{'MooseX/Prototype.pm'} = __FILE__;

	use Sub::Exporter -setup => {
		exports => [
			create_class_from_prototype => \&_build_create_class_from_prototype,
			object                      => \&_build_object,
		],
		groups  => {
			default => [qw/ object /],
		},
	};
		
	sub _build_create_class_from_prototype
	{
		my ($class, $name, $arg) = @_;
		
		my $IS   = $arg->{ -is   } || 'rw';
		my $BASE = $arg->{ -base } || 'Moose::Object';
		my $ROLE = $arg->{ -role } || (
			$IS eq 'ro'
				? 'MooseX::Prototype::Trait::Object::RO'
				: 'MooseX::Prototype::Trait::Object::RW'
		);
		
		return sub
		{
			my ($instance, $opts) = @_;
			$opts = { name => $opts } if defined $opts && !ref $opts;
			
			$opts->{name} ||= $serial_name->();
			
			Moose::Meta::Class::->create(
				$opts->{name},
				superclasses  => [ ref $instance ],
				roles         => [ $ROLE ],
				attributes    => $instance->$cloned_attributes,
			);
			return $opts->{name};
		}
	}
	
	sub _build_object
	{
		my ($class, $name, $arg) = @_;
		
		my $IS   = $arg->{ -is   } || 'rw';
		my $BASE = $arg->{ -base } || 'Moose::Object';
		my $ROLE = $arg->{ -role } || (
			$IS eq 'ro'
				? 'MooseX::Prototype::Trait::Object::RO'
				: 'MooseX::Prototype::Trait::Object::RW'
		);
		
		return sub ($)
		{
			my $hash  = ref $_[0] ? shift : +{@_};
			my $class = Moose::Meta::Class::->create(
				$serial_name->(),
				superclasses  => [ $BASE ],
				roles         => [ $ROLE ],
				attributes    => [
					map  { $mk_attribute->($_, $IS) }
					grep { not /^\&/ }
					keys %$hash
				],
				methods       => {
					map  { ; substr($_, 1) => $hash->{$_} }
					grep { /^\&/ }
					keys %$hash
				},
			);
			return $class->name->new({
				map  { ; $_ => $hash->{$_} }
				grep { not /^\&/ }
				keys %$hash
			});
		}
	}
	
	*create_class_from_prototype = __PACKAGE__->_build_create_class_from_prototype;
	*object                      = __PACKAGE__->_build_object;
};

BEGIN {
	package MooseX::Prototype::Trait::Object;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	$INC{'MooseX/Prototype/Trait/Object.pm'} = __FILE__;
	
	use Moose::Role;
	
	sub create_class { goto \&MooseX::Prototype::create_class_from_prototype };
	
	requires '_attribute_accessor_type';
	
	around new => sub {
		my ($orig, $class, @args) = @_;
		if (ref $class)
		{
			return $class->create_class->new(@args);
		}
		$class->$orig(@args);
	};
	
	around [qw/ does DOES /] => sub {
		my ($orig, $self, $role) = @_;
		return 1 if $role eq -proto;
		return $self->$orig($role);
	};
	
	sub extend {
		my $self = shift;
		my $hash = ref($_[0]) ? $_[0] : +{@_};
		my $extension = Moose::Meta::Class::->create(
			$serial_name->(),
			superclasses  => [ ref $self ],
			attributes    => [
				map  { $mk_attribute->($_) }
				grep { not /^\&/ }
				keys %$hash
			],
			methods       => {
				map  { ; substr($_, 1) => $hash->{$_} }
				grep { /^\&/ }
				keys %$hash
			},
		);
		bless $self, $extension->name;
		if ($self->DOES('MooseX::Prototype::Trait::Object::RO'))
		{
			foreach my $key (keys %$hash)
			{
				next if $key =~ /^\&/;
				# breaks Moose encapsulation :-(
				$self->{$key} = $hash->{$key};
			}
		}
		else
		{
			foreach my $key (keys %$hash)
			{
				next if $key =~ /^\&/;
				$self->$key($hash->{$key});
			}
		}
		return $self;
	}
};

BEGIN {
	package MooseX::Prototype::Trait::Object::RO;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	$INC{'MooseX/Prototype/Trait/Object/RO.pm'} = __FILE__;
	use Moose::Role;
	with qw( MooseX::Prototype::Trait::Object );
	sub _attribute_accessor_type { 'ro' };
};

BEGIN {
	package MooseX::Prototype::Trait::Object::RW;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	$INC{'MooseX/Prototype/Trait/Object/RW.pm'} = __FILE__;
	use Moose::Role;
	with qw( MooseX::Prototype::Trait::Object );
	sub _attribute_accessor_type { 'rw' };
};

1;

__END__

=head1 NAME

MooseX::Prototype - prototype-based programming for Moose

=head1 SYNOPSIS

From Wikipedia: I<< "Prototype-based programming is a style of object-oriented
programming in which classes are not present, and behaviour reuse (known as
inheritance in class-based languages) is performed via a process of cloning
existing objects that serve as prototypes." >>

   use MooseX::Prototype;
   
   my $Person = object {
      name       => undef,
   };
   
   my $Employee = $Person->new->extend({
      job        => undef,
      employer   => undef,
   });
   
   my $CivilServant = $Employee->new(
      employer   => 'Government',
   );
   
   $CivilServant->extend({
      department => undef,
   });
   
   my $bob = $CivilServant->new(
      name       => 'Robert',
      department => 'HMRC',
      job        => 'Tax Inspector',
   );
   
   print $bob->dump;
   
   # $VAR1 = bless( {
   #    name       => 'Robert',
   #    job        => 'Tax Inspector',
   #    department => 'HMRC',
   #    employer   => 'Government'
   # }, 'MooseX::Prototype::__ANON__::0006' );

=head1 DESCRIPTION

Due to familiarity with class-based languages such as Java, many
programmers assume that object-oriented programming is synonymous with
class-based programming. However, class-based programming is just one
kind of object-oriented programming style, and other varieties exist
such as role-oriented, aspect-oriented and prototype-based programming.

A prominent example of a prototype-based programming language is
ECMAScript (a.k.a. Javascript/JScript/ActionScript). ECMAScript does
provide a thin class-like layer over the top of its prototype-based
OO system, which some (even experienced) ECMAScript developers rarely
see beyond.

This module implements a thin prototype-like layer on top of L<Moose>'s
class/role-based toolkit.

=head2 Ex-Nihilo Object Creation

In prototype-based languages, objects are created by cloning other
objects. But it's often useful to be able to magic up an object out of
nowhere. MooseX::Prototype provides a convenience function to do this:

=over

=item C<< object \%attrs >>

Creates a new object with the given attributes. The hash is treated
as attribute-name, attribute-value pairs, but any names beginning with
C<< "&" >> are installed as methods. For example:

   my $person = object {
      "name"         => "Robert",
      "&changeName"  => sub {
         my ($self, $newname) = @_;
         $self->name($newname);
      },
   };

Objects created this way inherit from L<Moose::Object> and perform the
C<MooseX::Prototype::Trait::Object> role.

=back

=head2 Creating Objects from a Prototype

A prototype is just an object. When you create a new object from it,
the prototype will be cloned and the new object will inherit all its
attributes and methods.

=over

=item C<< $prototype->new(%attrs) >>

Creates a new object which inherits its methods and attributes from
C<< $prototype >>. The C<< %attrs >> hash can override attribute values
from the prototype, but cannot add new attributes or methods.

This method is provided by the C<MooseX::Prototype::Trait::Object>
role, so C<< $prototype >> must perform that role.

=item C<< $prototype->create_class >>

Rather than creating a new object from a prototype, this creates a whole
new Moose class which can be used to instantiate objects. If you need to
create a whole bunch of objects from a prototype, it is probably more
efficient to create a class and use that, rather than just calling C<new>
a bunch of times.

The class can be given a name, a la:

   $prototype->create_class("Foo::Bar");

Otherwise an arbitary name will be generated and returned.

This method is provided by the C<MooseX::Prototype::Trait::Object>
role, so C<< $prototype >> must perform that role.

=item C<< create_class_from_prototype($prototype) >>

A convenience function allowing you to use arbitary Moose objects (which
lack the C<create_class> method) as prototypes.

Also note:

   my $obj = create_class_from_prototype($proto)->new(%attrs);

This function is not exported by default, but can be exported using:

   use MooseX::Prototype -all;

=back

=head2 Extending Existing Objects

A key feature of Javascript is that new attributes and methods can be given
to an object using simple assignment;

   my_object.some_attribute = 123;
   my_object.some_method = function () { return 456 };

In MooseX::Prototype, there is an explicit syntax for adding new attributes
and methods to an object.

=over

=item C<< $object->extend(\%attrs) >>

As per ex-nihilo object creation, the attribute hashref can define attribute
name-value pairs, or new methods with a leading C<< "&" >>.

=back

=head1 HISTORY

Version 0.001 of MooseX::Prototype consisted of just a single function,
C<use_as_prototype> which was much the same as C<create_class_from_prototype>.

Version 0.002 is an almost complete rewrite.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-Prototype>.

=head1 SEE ALSO

L<Object::Prototype>,
L<Class::Prototyped>,
L<JE::Object>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

