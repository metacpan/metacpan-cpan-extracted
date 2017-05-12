package MooX::Struct;

use 5.008;
use strict;
use warnings;
use utf8;

BEGIN {
	$MooX::Struct::AUTHORITY = 'cpan:TOBYINK';
	$MooX::Struct::VERSION   = '0.014';
}

use Moo          1.000000;
use Object::ID   0         qw(      );
use Scalar::Does 0         qw( does );

use overload
	q[""]      => 'TO_STRING',
	q[bool]    => sub { 1 },
	q[@{}]     => 'TO_ARRAY',
	q[=]       => 'CLONE',
	fallback   => 1;

METHODS: {
	no warnings;
	sub OBJECT_ID   { goto \&Object::ID::object_id };
	sub FIELDS      { qw() };
	sub TYPE        { +undef };
	sub TO_ARRAY    {  [ map {;       $_[0]->$_ } $_[0]->FIELDS ] };
	sub TO_HASH     { +{ map {; $_ => $_[0]->$_ } $_[0]->FIELDS } };
	sub TO_STRING   { join q[ ], @{ $_[0]->TO_ARRAY } };
	sub CLONE       { my $s = shift; ref($s)->new(%{$s->TO_HASH}, @_) };
};

sub BUILDARGS
{
	my $class  = shift;
	my @fields = $class->FIELDS;
	
	if (
		@_ == 1                 and
		does($_[0], 'ARRAY')    and
		not does($_[0], 'HASH')
	)
	{
		my @values = @{ $_[0] };
		Carp::confess("too many values passed to constructor (expected @fields); stopped")
			unless @fields >= @values;
		no warnings;
		return +{
			map {
				$fields[$_] => $values[$_];
			} 0 .. $#values
		}
	}

	elsif (@_ == 1 and does($_[0], 'HASH') and not ref($_[0]) eq 'HASH')
	{
		# help Moo::Object!
		@_ = +{ %{$_[0]} };
	}

	my $hashref = $class->SUPER::BUILDARGS(@_);
	
#	my %tmp = map { $_ => 1 } keys %$hashref;
#	delete $tmp{$_} for @fields;
#	if (my @unknown = sort keys %tmp)
#	{
#		Carp::confess("unknown keys passed to constructor (@unknown); stopped");
#	}
	
	return $hashref;
}

sub EXTEND
{
	my ($invocant, @args) = @_;
	my $base = $invocant;
	$base = ref $invocant if ref $invocant;
	
	my $processor = 'MooX::Struct::Processor'->new;
	while (@args) {
		last unless $args[0] =~ /^-(.+)$/;
		$processor->flags->{ lc($1) } = !!shift @args;
	}

	my $subname = undef;
	$subname = ${ shift @args } if ref($args[0]) eq 'SCALAR';

	my $new_class = $processor->make_sub(
		$subname,
		[ -extends => [$base], @args ],
	)->();
	return $new_class unless ref $invocant;
	
	bless $invocant => $new_class;
}

# This could do with some improvement from a Data::Printer expert.
#
my $done = 0;
sub _data_printer
{
	require Data::Printer::Filter;
	require Term::ANSIColor;
	my $self   = shift;
	
	my @values = map { scalar &Data::Printer::p(\$_, return_value => 'dump') } @$self;
	my $label  = Term::ANSIColor::colored($self->TYPE||'struct', 'bright_yellow');

	if (grep /\n/, @values)
	{
		return sprintf(
			"%s[\n\t%s,\n]",
			$label,
			join(qq[,\n\t], map { s/\n/\n\t/gm; $_ } @values),
		);
	}
	
	sprintf('%s[ %s ]', $label, join q[, ], @values);
}

BEGIN {
	package MooX::Struct::Processor;
	
	{
		no warnings;
		our $AUTHORITY = 'cpan:TOBYINK';
		our $VERSION   = '0.014';
	}
	
	sub _uniq { my %seen; grep { not $seen{$_}++ } @_ };
	
	use Moo                  1.000000;
	use Carp                 0         qw( confess      );
	use Data::OptList        0         qw(              );
	use Sub::Install         0         qw( install_sub  );
	use Scalar::Does         0         qw( does blessed looks_like_number );
	use namespace::clean               qw(              );
	use B::Hooks::EndOfScope           qw( on_scope_end );
	
	has flags => (
		is       => 'ro',
		isa      => sub { die "flags must be HASH" unless does $_[0], 'HASH' },
		default  => sub { +{} },
	);
	
	has class_map => (
		is       => 'ro',
		isa      => sub { die "class_map must be HASH" unless does $_[0], 'HASH' },
		default  => sub { +{} },
	);
	
	has base => (
		is       => 'ro',
		default  => sub { 'MooX::Struct' },
	);
	
	has trace => (
		is       => 'lazy',
	);
	
	sub _build_trace
	{
		$ENV{PERL_MOOX_STRUCT_TRACE}
		or shift->flags->{trace};
	}
	
	has trace_handle => (
		is       => 'lazy',
	);
	
	sub _build_trace_handle
	{
		require IO::Handle;
		\*STDERR;
	}
	
	my $counter = 0;
	sub create_class
	{
		my ($self, $opts) = @_;
		my $klass;
		for my $o (@$opts) {
			next unless $o->[0] eq '-class';
			$klass = ref($o->[1]) eq 'ARRAY' ? join('::', @{$o->[1]}) : ${$o->[1]};
			last;
		}
		$klass = sprintf('%s::__ANON__::%04d', $self->base, ++$counter) unless defined $klass;
		"Moo"->_set_superclasses($klass, $self->base);
		"Moo"->_maybe_reset_handlemoose($klass);
		if ($self->trace)
		{
			$self->trace_handle->printf(
				"package %s;\nuse Moo;\n",
				$klass,
			);
		}
		return $klass;
	}
	
	sub process_meta
	{
		my ($self, $klass, $name, $val) = @_;
		
		if ($name eq '-extends' or $name eq '-isa')
		{
			my @parents = map {
				exists $self->class_map->{$_}
					? $self->class_map->{$_}->()
					: $_
			} @$val;
			"Moo"->_set_superclasses($klass, @parents);
			"Moo"->_maybe_reset_handlemoose($klass);
			
			if ($self->trace)
			{
				$self->trace_handle->printf(
					"extends qw(%s)\n",
					join(q[ ] => @parents),
				);
			}
			
			return map { $_->can('FIELDS') ? $_->FIELDS : () } @parents;
		}
		elsif ($name eq '-with')
		{
			require Moo::Role;
			"Moo::Role"->apply_roles_to_package($klass, @$val);
			"Moo"->_maybe_reset_handlemoose($klass);
			
			if ($self->trace)
			{
				$self->trace_handle->printf(
					"with qw(%s)\n",
					join(q[ ] => @$val),
				);
			}
			
			return
			#	map  { my $role = $_; grep { not ref $_ } @{ $Moo::Role::INFO{$role}{attributes} } }
			#	@$val;
		}
		elsif ($name eq '-class')
		{
			# skip; already handled by 'create_class' method (hopefully)
		}
		else
		{
			confess("option '$name' unknown");
		}
		
		return;
	}
	
	sub process_method
	{
		my ($self, $klass, $name, $coderef) = @_;
		install_sub {
			into   => $klass,
			as     => $name,
			code   => $coderef,
		};
		if ($self->trace)
		{
			$self->trace_handle->printf(
				"sub %s { ... }\n",
				$name,
			);
			if ($self->flags->{deparse})
			{
				require B::Deparse;
				my $code = "B::Deparse"->new(qw(-q -si8T))->coderef2text($coderef);
				$code =~ s/^/# /mig;
				$self->trace_handle->printf("$code\n");
			}
		}
		return;
	}
	
	sub process_spec
	{
		my ($self, $klass, $name, $val) = @_;
		
		my %spec = (
			is => ($self->flags->{rw} ? 'rw' : 'ro'),
			( does($val, 'ARRAY')
				? @$val
				: ( does($val,'HASH') ? %$val : () )
			),
		);
		
		if ($name =~ /^(.+)\!$/)
		{
			$name = $1;
			$spec{required} = 1;
		}
		
		if ($name =~ /^\@(.+)/)
		{
			$name = $1;
			$spec{isa} ||= sub {
				die "wrong type for '$name' (not arrayref)"
					unless does($_[0], 'ARRAY');
			};
		}
		elsif ($name =~ /^\%(.+)/)
		{
			$name = $1;
			$spec{isa} ||= sub {
				die "wrong type for '$name' (not hashref)"
					unless does($_[0], 'HASH');
			};
		}
		elsif ($name =~ /^\+(.+)/)
		{
			$name = $1;
			$spec{isa} ||= sub {
				die "wrong type for '$name' (not number)"
					unless looks_like_number($_[0]);
			};
			$spec{default} ||= sub { 0 } unless $spec{required};
		}
		elsif ($name =~ /^\$(.+)/)
		{
			$name = $1;
			$spec{isa} ||= sub {
				my $ref = ref($_[0]);
				die "wrong type for '$name' (should not be arrayref or hashref)"
					if $ref eq 'ARRAY' || $ref eq 'HASH';
			};
		}
		
		return ($name, \%spec);
	}
	
	sub process_attribute
	{
		my ($self, $klass, $name, $val) = @_;
		my $spec;
		($name, $spec) = $self->process_spec($klass, $name, $val);
		
		if ($self->trace)
		{
			require Data::Dumper;
			my $spec_str = "Data::Dumper"->new([$spec])->Terse(1)->Indent(0)->Sortkeys(1)->Dump;
			$spec_str =~ s/(^\{)|(\}$)//g;
			$self->trace_handle->printf(
				"has %s => (%s);\n",
				$name,
				$spec_str,
			);
			if ($self->flags->{deparse} and $spec->{isa})
			{
				require B::Deparse;
				my $code = "B::Deparse"->new(qw(-q -si8T))->coderef2text($spec->{isa});
				$code =~ s/^/# /mig;
				$self->trace_handle->printf("$code\n");
			}
		}
		
		"Moo"
			->_constructor_maker_for($klass)
			->register_attribute_specs($name, $spec);
			
		"Moo"
			->_accessor_maker_for($klass)
			->generate_method($klass, $name, $spec);
			
		"Moo"
			->_maybe_reset_handlemoose($klass);
		
		return $name;
	}
	
	# returns a list of "fields" resulting from the argument
	sub process_argument
	{
		my $self = shift;
		my ($klass, $name, $val) = @_;
		
		return $self->process_meta(@_)      if $name =~ /^-/;
		return $self->process_method(@_)    if does($val, 'CODE');
		return $self->process_attribute(@_);
	}
	
	sub make_sub
	{
		my ($self, $subname, $proto) = @_;
		return sub (;$)
		{
			1; # bizarre, but necessary if $] < 5.014
			if (ref $proto)  # inflate!
			{
				my $opts   = Data::OptList::mkopt($proto);
				my $klass  = $self->create_class($opts);
				my $seen_extends;
				my @fields = _uniq map {
					++$seen_extends if $_->[0] eq '-extends';
					$self->process_argument($klass, @$_);
				} @$opts;
				unshift @fields, $self->base->FIELDS
					if !$seen_extends && $self->base->can('FIELDS');
				$self->process_method($klass, FIELDS => sub { @fields });
				$self->process_method($klass, TYPE   => sub { $subname }) if defined $subname;
				$proto = $klass;
			}
			return $proto->new(@_) if @_;
			return $proto;
		}
	}
	
	sub process
	{
		my $self   = shift;
		my $caller = shift;
		
		while (@_ and $_[0] =~ /^-(.+)$/) {
			$self->flags->{ lc($1) } = !!shift;
		}
		
		foreach my $arg (@{ Data::OptList::mkopt(\@_) })
		{
			my ($subname, $details) = @$arg;
			$details = [] unless defined $details;
			
			$self->class_map->{ $subname } = $self->make_sub($subname, $details);
			install_sub {
				into   => $caller,
				as     => $subname,
				code   => $self->class_map->{ $subname },
			};
		}
		
		on_scope_end {
			namespace::clean->clean_subroutines(
				$caller,
				keys %{ $self->class_map },
			);
		} unless $self->flags->{ retain };
	}
};

sub import
{
	my $caller = caller;
	my $class  = shift;
	"$class\::Processor"->new->process($caller, @_);
}

no Moo;
1;

__END__

=head1 NAME

MooX::Struct - make simple lightweight record-like structures that make sounds like cows

=head1 SYNOPSIS

 use MooX::Struct
    Point   => [ 'x', 'y' ],
    Point3D => [ -extends => ['Point'], 'z' ],
 ;
 
 my $origin = Point3D->new( x => 0, y => 0, z => 0 );
 
 # or...
 my $origin = Point3D[ 0, 0, 0 ];

=head1 DESCRIPTION

MooX::Struct allows you to create cheap struct-like classes for your data
using L<Moo>.

While similar in spirit to L<MooseX::Struct> and L<Class::Struct>, 
MooX::Struct has a somewhat different usage pattern. Rather than providing
you with a C<struct> keyword which can be used to define structs, you
define all the structs as part of the C<use> statement. This means they
happen at compile time.

A struct is just an "anonymous" Moo class. MooX::Struct creates this class
for you, and installs a lexical alias for it in your namespace. Thus your
module can create a "Point3D" struct, and some other module can too, and
they won't interfere with each other. All struct classes inherit from
MooX::Struct.

Arguments for MooX::Struct are key-value pairs, where keys are the struct
names, and values are arrayrefs.

 use MooX::Struct
    Person   => [qw/ name address /],
    Company  => [qw/ name address registration_number /];

The elements in the array are the attributes for the struct (which will be
created as read-only attributes), however certain array elements are treated
specially.

=over

=item *

As per the example in the L</SYNOPSIS>, C<< -extends >> introduces a list of
parent classes for the struct. If not specified, then classes inherit from
MooX::Struct itself.

Structs can inherit from other structs, or from normal classes. If inheriting
from another struct, then you I<must> define both in the same C<use> statement.
Inheriting from a non-struct class is discouraged.

 # Not like this.
 use MooX::Struct Point   => [ 'x', 'y' ];
 use MooX::Struct Point3D => [ -extends => ['Point'], 'z' ];
 
 # Like this.
 use MooX::Struct
    Point   => [ 'x', 'y' ],
    Point3D => [ -extends => ['Point'], 'z' ],
 ;

=item *

Similarly C<< -with >> consumes a list of roles.

=item *

If an attribute name is followed by a coderef, this is installed as a
method instead.

 use MooX::Struct
    Person => [
       qw( name age sex ),
       greet => sub {
          my $self = shift;
          CORE::say "Hello ", $self->name;
       },
    ];

But if you're defining methods for your structs, then you've possibly missed
the point of them.

=item *

If an attribute name is followed by an arrayref, these are used to set the
options for the attribute. For example:

 use MooX::Struct
    Person  => [ name => [ is => 'ro', required => 1 ] ];

Using the C<init_arg> option would probably break stuff. Don't do that.

=item *

Attribute names may be "decorated" with prefix and postfix "sigils". The prefix
sigils of C<< @ >> and C<< % >> specify that the attribute isa arrayref or
hashref respectively. (Blessed arrayrefs and hashrefs are accepted; as are
objects which overload C<< @{} >> and C<< %{} >>.) The prefix sigil C<< $ >>
specifies that the attribute value must not be an unblessed arrayref or hashref.
The prefix sigil C<< + >> indicates the attribute is a number, and provides
a default value of 0, unless the attribute is required. The postfix sigil
C<< ! >> specifies that the attribute is required.

 use MooX::Struct
    Person  => [qw( $name! @children )];

 Person->new();         # dies, name is required
 Person->new(           # dies, children should be arrayref
    name     => 'Bob',
    children => 2,
 );

=back

Prior to the key-value list, some additional flags can be given. These begin
with hyphens. The flag C<< -rw >> indicates that attributes should be
read-write rather than read-only.

 use MooX::Struct -rw,
    Person => [
       qw( name age sex ),
       greet => sub {
          my $self = shift;
          CORE::say "Hello ", $self->name;
       },
    ];

The C<< -retain >> flag can be used to indicate that MooX::Struct should
B<not> use namespace::clean to enforce lexicalness on your struct class
aliases.

Flags C<< -trace >> and C<< -deparse >> may be of use debugging.

=head2 Instantiating Structs

There are two supported methods of instatiating structs. You can use a
traditional class-like constructor with named parameters:

 my $point = Point->new( x => 1, y => 2 );

Or you can use the abbreviated syntax with positional parameters:

 my $point = Point[ 1, 2 ];

If you know about Moo and peek around in the source code for this module,
then I'm sure you can figure out additional ways to instantiate them, but
the above are the only supported two.

When inheritance or roles have been used, it might not always be clear what
order the positional parameters come in (though see the documentation for the
C<FIELDS> below), so the traditional class-like style may be preferred.

=head2 Methods

Structs are objects and thus have methods. You can define your own methods
as described above. MooX::Struct's built-in methods will always obey the
convention of being in ALL CAPS (except in the case of C<_data_printer>).
By using lower-case letters to name your own methods, you can avoid
naming collisions.

The following methods are currently defined. Additionally all the standard
Perl (C<isa>, C<can>, etc) and Moo (C<new>, C<does>, etc) methods are
available.

=over

=item C<OBJECT_ID> 

Returns a unique identifier for the object.

=item C<FIELDS> 

Returns a list of fields associated with the object. For the C<Point3D> struct
in the SYNPOSIS, this would be C<< 'x', 'y', 'z' >>.

The order the fields are returned in is equal to the order they must be supplied
for the positional constructor.

Attributes inherited from roles, or from non-struct base classes are not included
in C<FIELDS>, and thus cannot be used in the positional constructor.

=item C<TYPE>

Returns the type name of the struct, e.g. C<< 'Point3D' >>.

=item C<TO_HASH>

Returns a reference to an unblessed hash where the object's fields are the
keys and the object's values are the hash values.

=item C<TO_ARRAY>

Returns a reference to an unblessed array where the object's values are the
array items, in the same order as listed by C<FIELDS>.

=item C<TO_STRING>

Joins C<TO_ARRAY> with whitespace. This is not necessarily a brilliant
stringification, but easy enough to overload:

 use MooX::Struct
    Point => [
       qw( x y ),
       TO_STRING => sub {
          sprintf "(%d, %d)"), $_[0]->x, $_[0]->y;
       },
    ]
 ;

=item C<CLONE>

Creates a shallow clone of the object. 

=item C<EXTEND>

An exverimental feature.

Extend a class or object with additional attributes, methods, etc. This method
takes almost all the same arguments as C<use MooX::Struct>, albeit with some
slight differences.

 use MooX::Struct Point => [qw/ +x +y /];
 my $point = Point[2, 3];
 $point->EXTEND(-rw, q/+z/);  # extend an object
 $point->can('z');   # true
 
 my $new_class = Point->EXTEND('+z');  # extend a class
 my $point_3d  = $new_class->new( x => 1, y => 2, z => 3 );
 $point_3d->TYPE;  # Point !
 
 my $point_4d = $new_class->EXTEND(\"Point4D", '+t');
 $point_4d->TYPE;  # Point4D
 
 my $origin = Point[]->EXTEND(-with => [qw/ Math::Role::Origin /]);

This feature has been included mostly because it's easy to implement on top
of the existing code for processing C<use MooX::Struct>. Some subsets of
this functionality are sane, such as the ability to add traits to an object.
Others (like the ability to add a new uninitialized, read-only attribute to
an existing object) are less sensible.

=item C<BUILDARGS>

Moo internal fu.

=item C<_data_printer>

Automatic pretty printing with L<Data::Printer>.

 use Data::Printer;
 use MooX::Struct Point => [qw/ +x +y /];
 my $origin = Point[];
 p $origin;

Use Data::Printer 0.36 or above please.

=back

With the exception of C<FIELDS> and C<TYPE>, any of these can be overridden
using the standard way of specifying methods for structs.

=head2 Overloading

MooX::Struct overloads stringification and array dereferencing. Objects always
evaluate to true in a boolean context. (Even if they stringify to the empty
string.)

=head1 CAVEATS

Because you only get an alias for the struct class, you need to be careful
with some idioms:

   my $point = Point3D->new(x => 1, y => 2, z => 3);
   $point->isa("Point3D");   # false!
   $point->isa( Point3D );   # true

   my %args  = (...);
   my $class = exists $args{z} ? "Point3D" : "Point";  # wrong!
   $class->new(%args);
   
   my $class = exists $args{z} ?  Point3D  :  Point ;  # right
   $class->new(%args);

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-Struct>.

=head1 SEE ALSO

L<Moo>, L<MooX::Struct::Util>, L<MooseX::Struct>, L<Class::Struct>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

