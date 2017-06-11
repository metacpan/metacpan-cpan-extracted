use 5.006;
use strict;
use warnings;

BEGIN { if ($] < 5.010000) { require UNIVERSAL::DOES } };

package Object::Util;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007';

use Carp                         qw( carp croak );
use List::Util       1.29        qw( pairkeys pairvalues );
use Scalar::Util     1.23        qw( blessed reftype );

my $anon_class_id = 0;

{
	my %op = (
		HASH    => '%{}',
		ARRAY   => '@{}',
		SCALAR  => '${}',
		CODE    => '&{}',
		GLOB    => '*{}',
		Regexp  => 'qr',
	);
	
	sub _is_reftype
	{
		my $object = shift;
		my $type   = $_[0];
		
		return !!1 if (reftype($object)||'') eq $type;
		return !!0 if not $INC{'overload.pm'};
		
		my $op = $op{$type} or return !!0;
		!!overload::Method($object, $op);
	}
}

sub _new :method
{
	my $class = shift;
	my $ref   = reftype($class);
	
	if ($ref)
	{
		croak "Invocant is not a coderef"
			unless _is_reftype($class, 'CODE');
	}
	else
	{
		require Module::Runtime;
		Module::Runtime::use_package_optimistically($class);
		croak "Class $class does not provide a constructor called 'new'"
			unless $class->can("new");
	}
	
	$ref ? $class->(@_) : $class->new(@_);
}

sub _call_if_object :method
{
	my $object = shift;
	my $method = shift;
	return unless blessed($object);
	$object->$method(@_);
}

for my $method (qw/ isa does DOES /)
{
	eval qq{
		sub _${method} :method
		{
			return unless Scalar::Util::blessed(\$_[0]);
			shift->${method}(\@_);
		}
		1;
	} or die "Internal problem: $@";
}

sub _can :method
{
	my $self = shift;
	return unless Scalar::Util::blessed($self);
	return $_[0] if ref($_[0]) eq 'CODE';
	$self->can(@_);
}

sub _try :method
{
	my $object = shift;
	my $method = shift;
	eval { $object->$method(@_) };
}

sub _tap :method
{
	my $object = shift;
	my $method = shift;
	$object->$method(@_);
	$object;
}

my %toolage;

sub _detect_metaclass
{
	my $class = shift;
	
	if ($INC{"Moo.pm"})
	{
		return "Moo" if $Moo::MAKERS{$class}{is_class};
	}
	
	if ($INC{'Moose.pm'})
	{
		require Moose::Util;
		return "Moose" if Moose::Util::find_meta($class);
	}
	
	if ($INC{'Mouse.pm'})
	{
		require Mouse::Util;
		return "Mouse" if Mouse::Util::find_meta($class);
	}
	
	my $meta;
	eval { $meta = $class->meta } or return "Other";
	
	return "Moo"   if ref($meta) eq "Moo::HandleMoose::FakeMetaClass";
	return "Mouse" if $meta->isa("Mouse::Meta::Module");
	return "Moose" if $meta->isa("Moose::Meta::Class");
	return "Moose" if $meta->isa("Moose::Meta::Role");
	return "Other";
}

sub _clone :method
{
	my $object = shift;
	my $class  = blessed($object);
	
	croak "Cannot call \$_clone on non-object"
		unless $class;
	
	return $object->clone(@_)
		if $object->can("clone");
	
	my $tool = ($toolage{$class} ||= _detect_metaclass($class));
	
	my %args = (@_ == 1 and ref($_[0]) eq "HASH") ? %{$_[0]} : @_;
	
	if ($tool eq "Moose")
	{
		require Moose::Util;
		my $meta = Moose::Util::find_meta($class);
		return $meta->clone_object($object, %args);
	}
	
	if ($tool eq "Mouse")
	{
		require Mouse::Util;
		my $meta = Mouse::Util::find_meta($class);
		return $meta->clone_object($object, %args);
	}
	
	croak "Object does not provide a 'clone' method, and is not a hashref"
		unless _is_reftype($object, 'HASH');
	
	ref($object)->Object::Util::_new({ %$object, %args });
}

sub _with_traits :method
{
	my $class = shift;
	
	if (ref $class)
	{
		croak "Cannot call \$_with_roles on reference"
			unless _is_reftype($class, 'CODE');
		
		if (@_)
		{
			my $factory    = $class;
			my @trait_list = @_;
			
			return sub {
				my $instance = $factory->(@_);
				_extend($instance, [@trait_list]);
			};
		}
	}
	
	return $class unless @_;
	
	my $tool = ($toolage{$class} ||= _detect_metaclass($class));
	
	if ($tool eq 'Moose')
	{
		require Moose::Util;
		require MooX::Traits::Util;
		
		my @traits = MooX::Traits::Util::resolve_traits($class, @_);
		return Moose::Util::with_traits($class, @traits);
	}
	
	if ($tool eq 'Mouse')
	{
		require Mouse::Util;
		require MooX::Traits::Util;
		
		my @traits = MooX::Traits::Util::resolve_traits($class, @_);
		
		my $meta = ref(Mouse::Util::find_meta($class))->create(
			sprintf('%s::__ANON__::%s', __PACKAGE__, ++$anon_class_id),
			superclasses => [ $class ],
			roles        => \@traits,
			cache        => 1,
		);
		return $meta->name;
	}
	
	require Role::Tiny;
	require MooX::Traits::Util;
	MooX::Traits::Util::new_class_with_traits($class, @_);
}

sub _dump :method
{
	require Data::Dumper;
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 1;
	local $Data::Dumper::Useqq = 1;
	local $Data::Dumper::Deparse = 1;
	local $Data::Dumper::Quotekeys = 0;
	local $Data::Dumper::Sortkeys = 1;
	local $Data::Dumper::Trailingcomma = 1;
	
	if ( _can($_[0], "dump") ) {
		return shift->dump(@_);
	}
	
	Data::Dumper::Dumper($_[0]);
}

sub _dwarn :method
{
	require Data::Dumper;
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 1;
	local $Data::Dumper::Useqq = 1;
	local $Data::Dumper::Deparse = 1;
	local $Data::Dumper::Quotekeys = 0;
	local $Data::Dumper::Sortkeys = 1;
	local $Data::Dumper::Trailingcomma = 1;
	
	warn Data::Dumper::Dumper(@_);
	
	wantarray ? @_ : $_[0];
}

sub _dwarn_call :method
{
	require Data::Dumper;
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 1;
	local $Data::Dumper::Useqq = 1;
	local $Data::Dumper::Deparse = 1;
	local $Data::Dumper::Quotekeys = 0;
	local $Data::Dumper::Sortkeys = 1;
	local $Data::Dumper::Trailingcomma = 1;
	
	my $object = shift;
	my $method = shift;
	my @args   = @_;
	
	warn "== INVOCANT ==\n";
	warn Data::Dumper::Dumper($object);

	warn "== METHOD ==\n";
	warn Data::Dumper::Dumper($method);

	if (@args) {
		warn "== ARGUMENTS ==\n";
		warn Data::Dumper::Dumper(@args);
	}
	
	my @r;
	if    (wantarray)         { @r = $object->$method(@args) }
	elsif (defined wantarray) { @r = scalar $object->$method(@args) }
	else                      { $object->$method(@args); undef; }
	
	if (defined wantarray) {
		warn "== RETURN ==\n";
		warn Data::Dumper::Dumper(@r);
	}
	
	wantarray ? @r : $r[0];
}

{
	my %_cache;
	sub _eigenclass
	{
		my $class = shift;
		my ($roles, $methods) = @_;
		
		my @traits;
		if ($roles and @$roles)
		{
			require MooX::Traits::Util;
			@traits = MooX::Traits::Util::resolve_traits($class, @$roles);
		}
		
		my $key = do
		{
			no warnings qw(once);
			require Storable;
			local $Storable::Deparse   = 1;
			local $Storable::canonical = 1;
			Storable::freeze( [$class, \@traits, $methods] );
		};
		
		my $eigenclass = $_cache{$key};
		unless ($eigenclass)
		{
			no strict qw(refs);
			$_cache{$key}
				= $eigenclass
				= sprintf('%s::__ANON__::%s', __PACKAGE__, ++$anon_class_id);
			
			my $tool = ($toolage{$class} ||= _detect_metaclass($class));
			if ($tool eq "Moose")
			{
				require Moose::Meta::Class;
				'Moose::Meta::Class'->create(
					$eigenclass => (
						superclasses => [$class],
						(roles       => \@traits) x!!@traits,
						methods      => $methods,
					),
				);
			}
			elsif ($tool eq "Mouse")
			{
				require Mouse::Meta::Class;
				'Mouse::Meta::Class'->create(
					$eigenclass => (
						superclasses => [$class],
						(roles       => \@traits) x!!@traits,
						methods      => $methods,
					),
				);
			}
			else
			{
				*{"$eigenclass\::ISA"} = [ _with_traits($class, @traits) ];
				*{"$eigenclass\::$_"}  = $methods->{$_} for keys %$methods;
			}
		}
		
		$eigenclass;
	}
}

sub _extend :method
{
	my $object = shift;
	my $class  = blessed($object)
		or croak("Cannot call \$_extend on non-object");
	
	my $roles   = _is_reftype($_[0], "ARRAY") ? shift : [];
	my $methods = _is_reftype($_[0], "HASH")  ? shift : {@_};
	
	return $object unless @$roles || keys(%$methods);
	bless $object, _eigenclass($class, $roles, $methods);
}

sub subs :method
{
	'$_new'             => \&_new,
	'$_isa'             => \&_isa,
	'$_can'             => \&_can,
	'$_does'            => \&_does,
	'$_DOES'            => \&_DOES,
	'$_call_if_object'  => \&_call_if_object,
	'$_tap'             => \&_tap,
	'$_try'             => \&_try,
	'$_clone'           => \&_clone,
	'$_with_traits'     => \&_with_traits,
	'$_dump'            => \&_dump,
	'$_dwarn'           => \&_dwarn,
	'$_dwarn_call'      => \&_dwarn_call,
	'$_extend'          => \&_extend,
}

sub sub_names :method
{
	my $me = shift;
	pairkeys($me->subs);
}

sub setup_for :method
{
	my $me   = shift;
	my @refs = @_;
	my @subs = pairvalues($me->subs);
	
	while (@refs)
	{
		my $ref = shift(@refs);
		my $sub = shift(@subs);
		die "Internal problem" unless _is_reftype($sub, 'CODE');
		
		$$ref = $sub;
		&Internals::SvREADONLY($ref, 1) if exists(&Internals::SvREADONLY);
	}
	
	die "Internal problem" if @subs;
	return;
}

sub import :method
{
	my $me = shift;
	my (%args) = @_;
	my ($caller, $file) = caller;
	
	$args{magic} = "auto" unless defined $args{magic};
	
	if ($file ne '-e'
	and $args{magic}
	and eval { require B::Hooks::Parser })
	{
		my $varlist = join ',', $me->sub_names;
		my $reflist = join ',', map "\\$_", $me->sub_names;
		B::Hooks::Parser::inject(";my($varlist);$me\->setup_for($reflist);");
		return;
	}
	
	if ($args{magic} and $args{magic} ne "auto")
	{
		carp "Object::Util could not use magic; continuing regardless";
	}
	
	my %subs = $me->subs;
	for my $sub_name (sort keys %subs)
	{
		my $code = $subs{$sub_name};
		$sub_name =~ s/^.//;
		no strict 'refs';
		*{"$caller\::$sub_name"} = \$code;
	}
}

1;

__END__

=pod

=encoding utf-8

=for stopwords metaobject

=head1 NAME

Object::Util - a selection of utility methods that can be called on blessed objects

=head1 SYNOPSIS

   use Object::Util;
   
   # $foo might be undef, but this should not die
   if ($foo->$_isa("Bar")) {
      ...;
   }

=head1 DESCRIPTION

This module is inspired by L<Safe::Isa>, L<Object::Tap>, and my own
OO experiences. It is a hopefully helpful set of methods for working
with objects, exposed as lexical coderef variables.

=head2 Rationale

Providing methods as coderefs so that you can do:

   $object->$_foo(@args)

... is unusual, so probably requires some explanation.

Firstly some of these methods are designed to be called on either a
blessed object or some kind of unblessed reference or value. Calling a
method on an unblessed reference like this will croak:

   $ref->foo(@args)

Ditto calling methods on undef. Coderefs don't suffer from that
problem.

More importantly though, the aim of this module is that these methods
should be available for you to call on I<any> object. You can only
call C<< $object->foo(@args) >> if C<< $object >>'s class implements a
method called C<foo>, or inherits from a superclass that does. Coderef
methods can be called on any object.

This module adopts the C<< $_foo >> naming convention pioneered by
modules such as Safe::Isa. However (unlike Safe::Isa) the coderefs it
provides are I<< true lexical variables >> (a.k.a. C<my> variables),
not package variables (a.k.a. C<our> variables).

=head2 Methods

=head3 Object construction and manipulation

=over

=item C<< $_new >>

Can be used like C<< $class->$_new(@args) >> to create a new object.
Object::Util will use L<Module::Runtime> to I<< attempt >> to load
C<< $class >> if it is not already loaded. C<< $class >> is expected
to provide a method called C<new>.

Can also be used as C<< $factory->$_new(@args) >> to create a new
object, where C<< $factory >> is a coderef or an object overloading
C<< &{} >>. In this case, C<< $_new >> will simply call
C<< $factory->(@args) >> and expect that to return an object.

=item C<< $_clone >>

If the object provides a C<clone> method, calls that. Or if the object
appears to be Moose- or Mouse-based, clones it using the metaobject
protocol.

Otherwise takes the naive approach of treating the object as a hashref
of attribute values, and creates a new object of the same class.

   # clone overrides some attributes from the original object
   my $glenda = $glen->$_clone(name => "Glenda", gender => "f");

That final fallback obviously massively breaks your class'
encapsulation, so it should be used sparingly.

=item C<< $_with_traits >>

Calling C<< $class->$_with_traits(@traits) >> will return a new class
name that does some extra traits. Should roughly support L<Moose>,
L<Mouse>, L<Moo>, and L<Role::Tiny>, though combinations of frameworks
(e.g. consuming a Moose role in a Mouse class) will not always work.

If C<< $class >> is actually a (factory) coderef, then this will only
I<partly> work. Example:

   my $factory  = sub { Foo->new(@_) };
   my $instance = $factory->$_with_traits("Bar")->$_new(%args);

The object C<< $instance >> should now be a C<Foo> object, and should
do the C<Bar> role, however if C<Bar> defines any I<attributes>, then
C<< $_new >> will not have initialized them correctly. This is because
of the opacity of the C<< $factory >>: C<< $_with_traits >> cannot
peek inside it and apply traits to the C<Foo> class; instead it needs
to build C<< $instance >> and apply the traits to the already-built
object. Therefore any behaviour that C<Bar> defines for the constructor
will have been ignored.

It is sometimes possible to work around this issue using:

   my $factory  = sub { Foo->new(@_) };
   my $instance = $factory->$_with_traits("Bar")->$_new(%args);
   $instance = $instance->$_clone(%args);

=item C<< $_extend >>

Calling C<< $object->$_extend(\@traits, \%methods) >> will add some
extra roles and/or methods to an existing object.

Either C<< @traits >> or C<< %methods >> may be omitted. That is,
C<< $object->$_extend(\@traits) >> will add some traits to an existing
object but no new methods, and C<< $object->$_extend(\%methods) >>
will add new methods, but no traits. C<< $object->$_extend() >> also
works fine, and is a no-op.

This method always returns C<< $object >>, which makes it suitable for
chaining.

Like L<Object::Extend>, but with added support for roles.

=back

=head3 Method call modifiers

=over

=item C<< $_call_if_object >>

C<< $object->$_call_if_object($method => @args) >> works like
C<< $object->$method(@args) >>, but if C<< $object >> is undefined,
returns C<undef> instead of throwing an exception.

C<< $method >> may be a method name, or a coderef (anonymous method).

Same as L<Safe::Isa>.

=item C<< $_try >>

C<< $object->$_try($method => @args) >> works like
C<< $object->$method(@args) >>, but if I<< any exception is thrown >>
returns C<undef> instead.

C<< $method >> may be a method name, or a coderef (anonymous method).

=item C<< $_tap >>

C<< $object->$_tap($method => @args) >> works like
C<< $object->$method(@args) >>, but discards the method's return value
(indeed it calls the method in void context), and instead returns the
object itself, making it useful for chaining.

C<< $method >> may be a method name, or a coderef (anonymous method).

Same as L<Object::Tap>, or the C<tap> method in Ruby.

=item C<< $_isa >>

C<< $object->$_isa($class) >> works like C<isa> as defined in
L<UNIVERSAL>, but if C<< $object >> is undefined, returns false
instead of throwing an exception.

A shortcut for C<< $object->$_call_if_method(isa => $class) >>.

Same as L<Safe::Isa>.

=item C<< $_does >>

C<< $object->$_does($role) >> works like C<does> as defined in
L<Moose::Object>, but if C<< $object >> is undefined, returns false
instead of throwing an exception.

A shortcut for C<< $object->$_call_if_method(does => $role) >>.

Same as L<Safe::Isa>.

=item C<< $_DOES >>

C<< $object->$_DOES($role) >> works like C<DOES> as defined in
L<UNIVERSAL>, but if C<< $object >> is undefined, returns false
instead of throwing an exception.

A shortcut for C<< $object->$_call_if_method(DOES => $role) >>.

Same as L<Safe::Isa>.

=item C<< $_can >>

C<< $object->$_can($method) >> works like C<can> as defined in
L<UNIVERSAL>, but if C<< $object >> is undefined, returns C<undef>
instead of throwing an exception.

There is one other significant deviation from the behaviour of
UNIVERSAL's C<can> method: C<< $_can >> also returns true if
C<$method> is an unblessed coderef. (The behaviour of C<$method> if it
is a blessed object -- particularly in the face of overloading -- can
be unintuitive, so is not supported by C<< $_can >>.)

Similar to L<Safe::Isa>, but not quite the same.

=back

=head3 Object utility methods

=over

=item C<< $_dump >>

Calling C<< $object->$_dump >> returns a L<Data::Dumper> dump of the
object, with some useful changes to the default Data::Dumper output.
(Same as L<Data::Dumper::Concise>.)

If the object provides its own C<dump> method, this will be called
instead. Any additional arguments will be passed through to it.

=item C<< $_dwarn >>

Calling C<< $object->$_dwarn(@args) >> prints a similar dump of the
object and any arguments as a warning, then returns the object, so
is suitable for tap-like chaining.

Unlike C<< $_dump >>, will not call the object's own C<dump> method.

=item C<< $_dwarn_call >>

Calling C<< $object->$_dwarn_call($method, @args) >> calls the
method on the object, passing it the arguments, and returns the
result. Along the way, it will dump the object, method, arguments,
and return value as warnings. Returns the method's return value.

Unlike C<< $_dump >>, will not call the object's own C<dump> method.

=back

=head2 Implementation Details

L<B::Hooks::Parser> is used to inject these methods into your
lexical scope, and C<Internals::SvREADONLY> (an internal function
built into the Perl core) is used to make them read-only, so you
can't do:

   use Object::Util;
   $_isa = sub { "something else" };

If this module detects that B::Hooks::Parser cannot be used on your
version of Perl, or your Perl is too old to have Internals::SvREADONLY,
then it has various fallback routes, but the variables it provides may
end up as package (C<our>) variables, or not be read-only.

If the magic works on your version of Perl, but you wish to avoid the
magic anyway, you can switch it off:

   use Object::Util magic => 0;

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Object-Util>.

=head1 SEE ALSO

L<Safe::Isa>, L<UNIVERSAL>, L<Object::Tap>, L<MooseX::Clone>,
L<Data::Dumper::Concise>, L<Object::Extend>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

