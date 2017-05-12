package POE::Declare;

=pod

=head1 NAME

POE::Declare - A POE abstraction layer for conciseness and simplicity

=head1 SYNOPSIS

  package MyComponent;
  
  use strict;
  use POE::Declare {
      foo      => 'Attribute',
      bar      => 'Internal',
      Username => 'Param',
      Password => 'Param',
  };
  
  declare TimeoutError => 'Message';
  
  sub hello : Event {
      print "Hello World!\n";
      $_[SELF]->hello_timeout_start;
  }
  
  sub hello_timeout : Timeout(30) {
      print "Alas, I die!\n";
  
      # Tell our parent as well
      $_[SELF]->TimeoutError;
  }
  
  compile;

=head1 DESCRIPTION

L<POE> is a very powerful and flexible system for doing asynchronous
programming. But it has the reputation of being difficult to learn,
with a somewhat confusing set of abstractions.

In particular, it can be tricky to resolve L<POE>'s way of programming
with the highly abstracted OO structures that many people are used to,
with layer stacked upon layer ad-infinitum to produce a delegation
heirachy which allows for powerful and complex systems that are relatively
easy to maintain.

This can be particularly noticable as the scale of a POE codebase gets
larger. At three levels of abstraction the layering in POE becomes quite
difficult, and progess past about the third layer of abstraction becomes
extremely difficult.

B<POE::Declare> is an attempt to resolve this problem by locking down
part of the traditional flexibility of POE, and by making it easier
to split the implementation of each object between an object-oriented
heirachy and a collection of POE sessions.

The goal is to retain the ability to build deep and complex heirachies
of encapsulated functionality in your application while also allowing
you to take advantage of the asynchronous nature of POE code.

=head2 General Architecture

At the core of any B<POE::Declare> application is an object-oriented
heirachy of components. This heirachy exists whether or not the POE
kernel is running, and parts of it can be started and stopped as needed.

When it is spawned, each component will create it's own private
L<POE::Session> in which to run its events and store its resources.

Each instance of a class always has one and only one session. This may
be a problem if your application will have thousands of spawned components
at once (POE recommends against the use of large numbers of sessions) but
should not be a problem as long as you keep it down to a few hundred
components.

Because the POE session is slaved to the L<POE::Declare::Object>, the
component can handle being started and stopped many times without the
loss of any state data between the creation and destruction of each
slave session.

To allow support for components that have no resources and only act as
supervisors, B<POE::Declare> always assigns a POE alias for the session
while it is active. The existance of this Alias prevents POE cleaning up
the session accidentally, and ensures components have explicit control
over when they want to shut down their sessions.

Each POE component contains a set of named resources. Resources may
consist of a different underlying POE resource, or may be made up of
multiple resources, and additional data stored in the matching object
HASH key. To ensure all the various underlying resources will not clash
with each other, all resources must be declared and will be strictly
checked.

At the end of each class, instead of the usual 1; to allow the package to
return true, you put instead a "compile;" statement.

This instructs L<POE::Declare> to inventory the declarations and attributes,
combine them with declarations from the parent classes, and then generate
the code that will implement the structures.

Once the class has been compiled, the installed functions will be removed
from the package to prevent run-time namespace pollution.

=head2 Import-Time Declaration

The cluster of "declare" statements at the beginning of a B<POE::Declare>
class can look ugly to some people, and may get annoying to step through in
the debugger.

To resolve this, you may optionally provide a list of slot declarations to
the module at compile time. This should be in the form of a simple C<HASH>
reference with the names as keys and the type as values.

  use My::Module {
      Foo => 'Param',
      Bar => 'Param',
  };

Event and timeout declarations cannot be provided by this method, and you
should continue to use subroutine attributes for these as normal.

=head2 Inheritance

The resource model of L<POE::Declare> correctly follows inheritance,
similar to the way declarations in L<Moose> are inherited. Resource types
in a parent class cannot be overwritten or modified in child classes.

No special syntax is needed for inheritance, as L<POE::Declare> works
directly on top of Perl's native inheritance.

  # Parent.pm - Object that connects to a service
  package My::Parent;
  
  use strict;
  use POE::Declare {
      Host           => 'Param',
      Port           => 'Param',
      ConnectSuccess => 'Message',
      ConnectFailure => 'Message',
  };
  
  sub connect : Event {
      # ...
  }
  
  compile;
  
  # Child.pm - Connect to an (optionally) authenticating service
  package My::Child;
  
  use strict;
  use base 'My::Parent';
  use POE::Declare {
      Username     => 'Param',
      Password     => 'Param',
      AuthRequired => 'Message',
      AuthInvalid  => 'Message',
  };
  
  compile;

=head1 CLASSES

B<POE::Declare> is composed of three main modules, and a tree of
slot/attribute classes.

=head2 POE::Declare

B<POE::Declare> provides the main interface layer and Domain
Specific API for declaratively building your POE::Declare classes.

=head2 POE::Declare::Object

L<POE::Declare::Object> is the abstract base class for all classes created
by B<POE::Declare>.

=head2 POE::Declare::Meta

L<POE::Declare::Meta> implements the metadata structures that describe
each of your B<POE::Declare> classes. This is superficially similar to
something like L<Moose>, but unlike Moose is fast, light weight and
can use domain-specific assumptions.

=head2 POE::Declare::Slot

  POE::Declare::Meta::Slot
    POE::Declare::Meta::Internal
    POE::Declare::Meta::Attribute
      POE::Declare::Meta::Param
    POE::Declare::Meta::Message
    POE::Declare::Meta::Event
      POE::Declare::Meta::Timeout

=head2 POE::Declare::Meta::Internal

L<POE::Declare::Meta::Internal> is a slot class that won't generate any
functionality, but allows you to reserve an attribute for internal use
so that they won't be used by any sub-classes.

=head2 POE::Declare::Meta::Attribute

L<POE::Declare::Meta::Attribute> is a slot class used for readable
attributes.

=head2 POE::Declare::Meta::Param

L<POE::Declare::Meta::Attribute> is a slot class for attributes that
are provided to the constructor as a parameter.

=head2 POE::Declare::Meta::Message

L<POE::Declare::Meta::Message> is a slot class for declaring messages that
the object will emit under various circumstances. Each message is a param
to the constructor that takes a callback in a variety of formats (usually
pointing up to the parent object).

=head2 POE::Declare::Meta::Event

L<POE::Declare::Meta::Event> is a class for named POE events that can be
called or yielded to by other POE messages/events.

=head2 POE::Declare::Meta::Timeout

L<POE::Declare::Meta::Timeout> is a L<POE::Declare::Meta::Event> sub-class
that is designed to trigger from an alarm and generates additional methods
to manage the alarms.

=head1 FUNCTIONS

For the first few releases, I plan to leave this module undocumented.

That I am releasing this distribution at all is more of a way to
mark my progress, and to allow other POE/OO people to look at the
implementation and comment.

=cut

use 5.008007;
use strict;
use warnings;
use Carp                  ();
use Exporter              ();
use List::Util       1.19 ();
use Params::Util     1.00 ();
use POE::Session          ();
use POE::Declare::Meta    ();
use POE 1.310;

# The base class requires POE::Declare to be fully compiled,
# so load it in post-BEGIN with a require rather than at
# BEGIN-time with a use.
require POE::Declare::Object;

# Provide the SELF constant
use constant SELF => HEAP;

use vars qw{$VERSION @ISA @EXPORT %ATTR %EVENT %META};
BEGIN {
	$VERSION = '0.59';
	@ISA     = qw{ Exporter };
	@EXPORT  = qw{ SELF declare compile };

	# Metadata Storage
	%ATTR    = ();
	%EVENT   = ();
	%META    = ();
}





#####################################################################
# Declaration Functions

sub import {
	my $pkg     = shift;
	my $callpkg = caller($Exporter::ExportLevel);

	# POE::Declare should only be loaded on empty classes.
	# We only use the simple case here of checking for $VERSION or @ISA
	no strict 'refs';
	if ( defined ${"$callpkg\::VERSION"} ) {
		Carp::croak("$callpkg already exists, cannot use POE::Declare");
	}
	if ( @{"$callpkg\::ISA"} ) {
		# Are we a subclass of an existing POE::Declare class
		unless ( $callpkg->isa('POE::Declare::Object') ) {
			# This isn't a POE::Declare class
			Carp::croak("$callpkg already exists, cannot use POE::Declare");
		}
	} else {
		# Set @ISA for the package, which does most of the work
		# We have to set this early, otherwise attribute declaration
		# won't work.
		@{"$callpkg\::ISA"} = qw{ POE::Declare::Object };
	}

	# Set a temporary meta function that will throw an exception
	*{"$callpkg\::meta"} = sub {
		Carp::croak("POE::Declare class $callpkg has not called compile()");
	};

	# Export the symbols
	local $Exporter::ExportLevel += 1;
	$pkg->SUPER::import();

	# Make "use POE::Declare;" an implicit "use POE;" as well
	eval "package $callpkg; use POE;";
	die $@ if $@;

	# If passed a HASH structure, treat them as a set of declare
	# calls so that the slots can be defined quickly and in a single
	# step during the load.
	if ( Params::Util::_HASH($_[0]) ) {
		my %declare = %{$_[0]};
		foreach my $name ( sort keys %declare ) {
			_declare( $callpkg, $name, $declare{$name} );
		}
	}

	return 1;
}

=pod

=head2 declare

  declare one   => 'Internal';
  declare two   => 'Attribute';
  declare three => 'Param';
  declare four  => 'Message';

The C<declare> function is exported by default. It takes two parameters,
a slot name and a slot type.

The slot name can be any legal Perl identifier.

The slot type should be one of C<Internal>, C<Attribute>, C<Param> or
C<Message>.

Creates the new slot, throws an exception on error.

=cut

sub declare (@) {
	my $pkg = caller();
	local $Carp::CarpLevel += 1;
	_declare( $pkg, @_ );
}

sub _declare {
	my $pkg = shift;
	if ( $META{$pkg} ) {
		Carp::croak("Too late to declare additions to $pkg");
	}

	# What is the name of the attribute
	my $name = shift;
	unless ( Params::Util::_IDENTIFIER($name) ) {
		Carp::croak("Did not provide a valid attribute name");
	}

	# Has the attribute already been defined
	if ( $ATTR{$pkg}->{$name} ) {
		Carp::croak("Attribute $name already defined in class $pkg");
	}

	# Resolve the attribute class
	my $type = do {
		local $Carp::CarpLevel += 1;
		_attribute_class(shift);
	};

	# Is the class an attribute class?
	unless ( $type->isa('POE::Declare::Meta::Slot') ) {
		Carp::croak("The class $type is not a POE::Declare::Slot");
	}

	# Create and save the attribute
	$ATTR{$pkg}->{$name} = $type->new(
		name => $name,
		@_,
	);

	return 1;
}

# Resolve an attribute type
sub _attribute_class {
	my $type = shift;
	if ( Params::Util::_IDENTIFIER($type) ) {
		$type = "POE::Declare::Meta::$type";
	} elsif ( Params::Util::_CLASS($type) ) {
		$type = $type;
	} else {
		Carp::croak("Invalid attribute type");
	}

	# Try to load the attribute class
	my $file = $type . '.pm';
	$file =~ s{::}{/}g;
	eval { require $file };
	if ( $@ ) {
		local $Carp::CarpLevel += 1;
		my $quotefile = quotemeta $file;
		if ( $@ =~ /^Can\'t locate $quotefile/ ) {
			Carp::croak("The attribute class $type does not exist");
		} else {
			Carp::croak($@);
		}
	}

	return $type;
}

=pod

=head2 compile

The C<compile> function indicates that all attributes and events have
been defined and the structure should be finalised and compiled.

Returns true or throws an exception.

=cut

sub compile () {
	my $pkg = caller();

	# Shortcut if already compiled
	return 1 if $META{$pkg};

	# Create the meta object
	my $meta  = $META{$pkg} = POE::Declare::Meta->new($pkg);
	my @super = reverse $meta->super_path;

	# Make sure any parent POE::Declare classes are compiled
	foreach my $parent ( @super ) {
		next if $META{$parent};
		Carp::croak("Cannot compile $pkg, parent class $parent not compiled");
	}

	# Are any attributes already defined in our parents?
	foreach my $name ( sort keys %{$ATTR{$pkg}} ) {
		my $found = List::Util::first { 
			$ATTR{$_}->{attr}->{$name}
		} @super;
		Carp::croak(
			"Duplicate attribute '$name' already defined in "
			. $found->name
		) if $found;
		$meta->{attr}->{$name} = $ATTR{$pkg}->{$name};
	}

	# Attempt to compile all the individual parts
	$meta->as_perl;
}

# Get the meta-object for a class.
# Primarily used for testing purposes.
sub meta {
	$META{$_[0]};
}

sub next_alias {
	my $meta = $META{$_[0]};
	unless ( $meta ) {
		Carp::croak("Cannot instantiate $_[0], class not defined");
	}
	$meta->next_alias;
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
