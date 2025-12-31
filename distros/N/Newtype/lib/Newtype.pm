use 5.014;
use strict;
use warnings;

package Newtype;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002000';

use Type::Tiny::Class 2.000000;
use parent 'Type::Tiny::Class';

use B qw( perlstring );
use Eval::TypeTiny qw( eval_closure set_subname );
use Types::Common qw( -types -is );
use namespace::autoclean;

sub import {
	my $class = shift;
	my $global_opts = +{ @_ && ref($_[0]) eq q(HASH) ? %{+shift} : () };

	if ( defined $global_opts->{into} and $global_opts->{into} eq '-lexical' ) {
		$global_opts->{lexical} = 1;
		delete $global_opts->{into};
	}
	if ( not defined $global_opts->{into} ) {
		$global_opts->{into} = caller;
	}
	
	my %newtypes;
	$global_opts->{Newtype} = \%newtypes;
	$class->SUPER::import( $global_opts, @_ );
	$class->_setup_delayed_coercions( \%newtypes, $global_opts->{into} );
}

sub _exporter_fail {
	my ( $class, $name, $opts, $globals ) = @_;
	my $caller = $globals->{into};

	$opts->{caller} = $caller;
	$opts->{name}   = $name;

	my $type = $class->new( $opts );

	$INC{'Type/Registry.pm'}
		? 'Type::Registry'->for_class( $caller )->add_type( $type )
		: ( $Type::Registry::DELAYED{$caller}{$type->name} = $type )
		unless( ref($caller) or $caller eq '-lexical' or $globals->{'lexical'} );

	$globals->{Newtype}{$name} = $type;

	return map +( $_->{name} => $_->{code} ), @{ $type->exportables };
}

sub new {
	my $class = shift;

	if ( is_Object $class ) {
		my $real_class = $class->class;
		return $real_class->new( $class->inner_type->( shift ) );
	}

	my %opts = ( @_ == 1 and is_HashRef $_[0] ) ? %{ $_[0] } : @_;

	if ( is_Undef $opts{inner} ) {
		die "Expected option: inner";
	}
	elsif ( is_Str $opts{inner} ) {
		$opts{inner} = 'Type::Tiny::Class'->new( class => $opts{inner} );
	}

	$opts{class} = $class->_make_newclass_name( \%opts );

	if ( $opts{coerce} ) {
		$opts{delayed_coercions} = delete $opts{coerce};
	}

	return $class
		->SUPER::new( %opts )
		->_make_newclass()
		->_make_coercions();
}

# Attributes
sub inner_type { $_[0]{inner} }
sub kind       { $_[0]{kind}  ||= $_[0]->_build_kind }

sub _build_kind {
	my $self = shift;
	my $inner_type = $self->inner_type;

	return 'Array'    if $inner_type->is_a_type_of( ArrayRef );
	return 'Bool'     if $inner_type->is_a_type_of( Bool );
	return 'Code'     if $inner_type->is_a_type_of( CodeRef );
	return 'Counter'  if $inner_type->is_a_type_of( Int );
	return 'Hash'     if $inner_type->is_a_type_of( HashRef );
	return 'Number'   if $inner_type->is_a_type_of( StrictNum )
	                  || $inner_type->is_a_type_of( LaxNum ); ##WS
	return 'Object'   if $inner_type->is_a_type_of( Object );
	return 'String'   if $inner_type->is_a_type_of( Str );

	die "Could not determine kind of inner type. Specify 'kind' option";
}

sub exportables {
	my $self = shift;
	my $inner_type = $self->inner_type;
	my @exportables = @{ $self->SUPER::exportables( @_ ) };
	for my $e ( @exportables ) {
		if ( $e->{tags}[0] eq 'types' ) {
			$e->{code} = sub (;$) {
				my ( $inner_value, @rest ) = @_
					or return $self;
				$inner_type->( $inner_value );
				my $wrapped_value = bless( \$inner_value, $self->{class} );
				wantarray ? ( $wrapped_value, @rest ) : $wrapped_value;
			};
		}
	}
	\@exportables;
}

sub _make_newclass_name {
	my ( $class, $opts ) = @_;
	return sprintf '%s::Newtype::%s', $opts->{caller}, $opts->{name};
}

sub _make_newclass {
	my ( $self ) = @_;

	my $class = $self->class;
	$self
		->_make_newclass_basics( $class )
		->_make_newclass_overloading( $class )
		->_make_newclass_metamethods( $class )
		->_make_newclass_native_methods( $class )
		->_make_newclass_custom_methods( $class );

	return $self;
}

sub _make_newclass_basics {
	my ( $self, $class ) = @_;

	my $inner_name = sprintf( '%s::INNER', $class );
	my $inner_code = eval_closure(
		environment => {},
		source => q{
			sub {
				my $self = shift;
				$$self;
			}
		},
	);

	my $constructor_name = sprintf( '%s::new', $class );
	my $constructor_code = eval_closure(
		environment => {},
		source => q{
			sub {
				my ( $class, $inner_value ) = @_;
				if ( Scalar::Util::blessed($inner_value) eq $class ) {
					return $inner_value;
				}
				return bless( \$inner_value, $class );
			}
		},
	);

	{
		no strict 'refs';
		*{$inner_name}       = set_subname( $inner_name,       $inner_code       );
		*{$constructor_name} = set_subname( $constructor_name, $constructor_code );
	}

	return $self;
}

sub _make_newclass_overloading {
	my ( $self, $class ) = @_;

	my $overloading = {
		Array     => '( q[@{}] => sub { ${+shift} }, bool => sub { !!1 }, fallback => 1 )',
		Bool      => '( bool => sub { !!${+shift} }, fallback => 1 )',
		Code      => '( q[&{}] => sub { ${+shift} }, bool => sub { !!1 }, fallback => 1 )',
		Counter   => '( q[0+] => sub { ${+shift} }, bool => sub { ${+shift} }, fallback => 1 )',
		Hash      => '( q[%{}] => sub { ${+shift} }, bool => sub { !!1 }, fallback => 1 )',
		Number    => '( q[0+] => sub { ${+shift} }, bool => sub { ${+shift} }, fallback => 1 )',
		String    => '( q[""] => sub { ${+shift} }, bool => sub { ${+shift} }, fallback => 1 )',
	}->{ $self->kind } or return $self;

	local $@;
	eval "package $class; use overload $overloading; 1" or die( $@ );

	return $self;
}

sub _make_newclass_metamethods {
	my ( $self, $class ) = @_;

	my $kind = $self->kind;
	my $known_class = $self->inner_type->find_parent( sub {
		$_->isa( 'Type::Tiny::Class' );
	} );

	if ( $kind eq 'Object' and is_Defined $known_class ) {
		return $self->_make_newclass_metamethods_for_known_class( $class, $known_class->class );
	}
	elsif ( $kind eq 'Object' ) {
		return $self->_make_newclass_metamethods_for_generic_object( $class );
	}
	else {
		return $self->_make_newclass_metamethods_for_kind( $class, $kind );
	}
}

sub _make_newclass_metamethods_for_known_class {
	my ( $self, $class, $parent_class ) = @_;

	local $@;
	eval q|
		package | . $class . q|;
		sub AUTOLOAD {
			my $self = shift;
			my ( $method ) = ( our $AUTOLOAD =~ /::(\w+)$/ );
			if ( ref($self) ) {
				if ( $method eq 'DESTROY' ) {
					my $found = $$self->can( 'DESTROY' ) or return;
					return $$self->$found( @_ );
				}
				return $$self->$method( @_ );
			}
			else {
				return "| . $parent_class . q|"->$method( @_ );
			}
		}
		sub isa {
			my ( $self, $c ) = @_;
			$c = $c->class if Scalar::Util::blessed($c) && $c->can('class');
			ref($self) && $$self->isa( $c ) or
				"| . $parent_class . q|"->isa( $c ) or
				$self->UNIVERSAL::isa( $c );
		}
		sub DOES {
			my ( $self, $r ) = @_;
			$r = $r->class if Scalar::Util::blessed($r) && $r->can('class');
			$r eq 'Newtype' or
				$r eq 'Object' or
				ref($self) && $$self->DOES( $r ) or
				"| . $parent_class . q|"->DOES( $r ) or
				$self->UNIVERSAL::DOES( $r );
		}
		sub can {
			my ( $self, $m ) = @_;
			ref($self) && $$self->can( $m ) or
				"| . $parent_class . q|"->can( $m ) or
				$self->UNIVERSAL::can( $m );
		}
		1;
	| or die( $@ );

	return $self;
}

sub _make_newclass_metamethods_for_generic_object {
	my ( $self, $class ) = @_;

	local $@;
	eval q|
		package | . $class . q|;
		sub AUTOLOAD {
			my $self = shift;
			ref($self) or return;
			my ( $method ) = ( our $AUTOLOAD =~ /::(\w+)$/ );
			if ( $method eq 'DESTROY' ) {
				my $found = $$self->can( 'DESTROY' ) or return;
				return $$self->$found( @_ );
			}
			$$self->$method( @_ );
		}
		sub isa {
			my ( $self, $c ) = @_;
			$c = $c->class if Scalar::Util::blessed($c) && $c->can('class');
			ref($self) && $$self->isa( $c ) or
				$self->UNIVERSAL::isa( $c );
		}
		sub DOES {
			my ( $self, $r ) = @_;
			$r = $r->class if Scalar::Util::blessed($r) && $r->can('class');
			$r eq 'Newtype' or
				$r eq 'Object' or
				ref($self) && $$self->DOES( $r ) or
				$self->UNIVERSAL::DOES( $r );
		}
		sub can {
			my ( $self, $m ) = @_;
			ref($self) && $$self->can( $m ) or
				$self->UNIVERSAL::can( $m );
		}
		1;
	| or die( $@ );

	return $self;
}

sub _make_newclass_metamethods_for_kind {
	my ( $self, $class, $kind ) = @_;

	local $@;
	eval q|
		package | . $class . q|;
		sub DOES {
			my ( $self, $r ) = @_;
			$r = $r->class if Scalar::Util::blessed($r) && $r->can('class');
			$r eq 'Newtype' or
				$r eq '| . $kind . q|' or
				$self->UNIVERSAL::DOES( $r );
		}
		1;
	| or die( $@ );

	return $self;
}

sub _make_newclass_native_methods {
	my ( $self, $class ) = @_;

	my $kind = $self->kind;
	return $self if $kind eq 'Object';

	my $inner_type = $self->inner_type;
	my $type_default = $inner_type->type_default // $self->_kind_default;

	require Sub::HandlesVia::CodeGenerator;
	my $gen = 'Sub::HandlesVia::CodeGenerator'->new(
		env => { '$type_default' => \$type_default },
		target => $class,
		attribute => 'Newtype',
		isa => $inner_type,
		coerce => $inner_type->has_coercion(),
		generator_for_self => sub { '$_[0]' },
		generator_for_slot => sub { my ( $g ) = @_; sprintf '${%s}', $g->generate_self },
		generator_for_get => sub { my ( $g ) = @_; $g->generate_slot },
		generator_for_set => sub { my ( $g, $v ) = @_; sprintf '(%s=%s)', $g->generate_slot, $v },
		generator_for_default => sub { sprintf('$type_default->()') },
		get_is_lvalue => !!1,
		set_checks_isa => !!0,
	);

	my $shv_lib = "Sub::HandlesVia::HandlerLibrary::$kind";
	eval "require $shv_lib; 1" or die( $@ );

	my %already;
	for my $h_name ( $shv_lib->handler_names ) {
		next if $already{$h_name}++;
		my $h = $shv_lib->get_handler( $h_name );
		$gen->generate_and_install_method( $h_name, $h );
	}

	return $self;
}

sub _kind_default {
	my ( $self ) = @_;

	return {
		Array     => sub { [] },
		Bool      => sub { !!0 },
		Code      => sub { sub {} },
		Counter   => sub { 0 },
		Hash      => sub { {} },
		Number    => sub { 0 },
		String    => sub { '' },
	}->{ $self->kind };
}

sub _make_newclass_custom_methods {
	my ( $self, $class ) = @_;

	no strict 'refs';

	my %methods = %{ $self->{methods} // {} };
	for my $name ( keys %methods ) {
		my $fq_name = "$class\::$name";
		*{$fq_name} = set_subname( $fq_name, $methods{$name} );
	}
}

sub _make_coercions {
	my $self = shift;
	my $class = $self->class;

	my $inner_type = $self->inner_type;
	my $coercion_from_inner_type = sprintf(
		q{do { my $x = $_; bless( \$x, %s ) }},
		perlstring( $class ),
	);
	$self->coercion->add_type_coercions(
		$inner_type,
		$coercion_from_inner_type,
	);

	if ( $inner_type->has_coercion ) {
		$self->coercion->add_type_coercions(
			$inner_type->coercibles(),
			sub {
				my $coerced_inner_value = $inner_type->coerce( $_ );
				$inner_type->check( $coerced_inner_value ) or return $_;
				return bless( \$coerced_inner_value, $class );
			},
		);
	}

	return $self;
}

sub _setup_delayed_coercions {
	my ( $class, $newtypes, $into ) = @_;
	
	for my $type ( values %$newtypes ) {
		if ( my $c = delete $type->{delayed_coercions} ) {
			require Type::Registry;
			my $reg = Type::Registry->for_class( $into );
			while ( @$c ) {
				my ( $from_type, $code ) = splice @$c, 0, 2;
				if ( is_Str $from_type ) {
					if ( my $lookup = $newtypes->{$from_type} ) {
						$from_type = $lookup;
					}
					else {
						$from_type = $reg->lookup( $into );
					}
				}
				is_TypeTiny $from_type
					or die "Unexpected entry in coercion list: $from_type";
				$type->coercion->add_type_coercions( $from_type, $code );
			}
		}
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Newtype - Perl implementation of an approximation for Haskell's newtype

=head1 SYNOPSIS

  package MyClass;
  
  use HTTP::Tiny ();
  use Newtype HttpTiny => { inner => 'HTTP::Tiny' };
  
  use Moo;
  
  has ua => (
    is => 'ro',
    isa => HttpTiny(),
    coerce => 1,
  );

=head1 DESCRIPTION

This module allows you to create a new type which is a subclass of an existing
type.

Why?

Well maybe you want to add some new methods to the new type:

  use HTTP::Tiny ();
  use Newtype HttpTiny => {
    inner => 'HTTP::Tiny',
    methods => {
      'post_or_get' => sub {
        my $self = shift;
        my $res = $self->post( @_ );
        return $res if $res->{success};
        return $self->get( @_ );
      },
  };

Or maybe you need to differentiate between two different kinds of things
which are otherwise the same class.

  use Newtype (
    SecureUA    => { inner => 'HTTP::Tiny' },
    InsecureUA  => { inner => 'HTTP::Tiny' },
  );
  
  ...;
  
  my $ua = InsecureUA( HTTP::Tiny->new );
  
  ...;
  
  if ( $ua->isa(SecureUA) ) {
    ...;
  }

Newtype can also create new types which "inherit" from Perl builtins.

  use Types::Common qw( ArrayRef PositiveInt );
  use Newtype Numbers => { inner => ArrayRef[PositiveInt] };
  
  my $nums = Numbers( [] );
  $nums->push(  1 );
  $nums->push(  2 );
  $nums->push( -1 );  # dies

See L<Hydrogen> for the list of available methods for builtins.

Newtypes which inherit from builtins use overloading to attempt to provide
transparency.

Although there will be exceptions to this general rule of thumb (especially
if your newtype is inheriting from a Perl builtin), you can think of things
like this: if you create a type B<NewFoo> from existing type B<Foo>, then
instances of B<NewFoo> should be accepted everywhere instances of B<Foo> are.
But instances of B<Foo> will not be automatically accepted where instances of
B<NewFoo> are.

=head2 Creating a newtype

The general form for creating newtypes is:

  use Newtype $typename => {
    inner => $inner_type,
    %other_options,
  };

The inner type is required, and must be either a string class name or
a L<Type::Tiny> type constraint indicating what type of thing you want
to wrap.

Other supported options are:

=over

=item C<methods>

A hashref of methods to add to the newtype. Keys are the method names.
Values are coderefs.

=item C<kind>

This allows you to give Newtype a hint for how to delegate to the inner
value. Supported kinds (case-sensitive) are: Array, Bool, Code, Counter,
Hash, Number, Object, and String. Usually Newtype will be able to guess
based on C<inner> though.

=item C<coerce>

See L</Coercions> below.

=back

=head2 Creating values belonging to the newtype

When you import a newtype B<Foo>, you import a function C<< Foo() >>
into your namespace. You can create instances of the newtype using:

  Foo( $inner_value )

Where C<< $inner_value >> is an instance of the type you're wrapping.

For example:

  use HTTP::Tiny;
  use Newtype UA => { inner => 'HTTP::Tiny' };
  
  my $ua = UA( HTTP::Tiny->new );

I<< Note: >> you also get C<is_Foo>, C<assert_Foo>, and C<to_Foo>
functions imported! C<< is_Foo( $x ) >> checks if C<< $x >> is a B<Foo>
object and returns a boolean. C<< assert_Foo( $x ) >> does the same,
but dies if it fails. C<< to_Foo( $x ) >> attempts to coerce C<< $x >>
to a B<Foo> object.

=head2 Integration with Moose, Mouse, and Moo

If your imported newtype is B<Foo>, then calling C<< Foo() >> with no
arguments will return a L<Type::Tiny> type constraint for the newtype.

  use HTTP::Tiny;
  use Newtype UA => { inner => 'HTTP::Tiny' };
  
  use Moo;
  has my_ua => ( is => 'ro', isa => UA() );

Now people instantiating your class will need to pass you a wrapped
HTTP::Tiny object instead of passing a normal HTTP::Tiny object. You may
wish to allow them to pass you a normal HTTP::Tiny object though.
That should be easy with coercions:

  has my_ua => ( is => 'ro', isa => UA(), coerce => 1 );

=head2 Accessing the inner value

You can access the original wrapped value using the C<< INNER >> method.

  my $ua = UA( HTTP::Tiny->new );
  my $http_tiny_object = $ua->INNER;

=head2 Introspection

If your newtype is called B<MyNewtype>, then you can introspect it using
a few methods:

=over

=item C<< MyNewtype->class >>

The class powering the newtype.

=item C<< MyNewtype->inner_type >>

The type constraint for the inner value.

=item C<< MyNewtype->kind >>

The kind of delegation being used.

=back

The object returned by C<< MyNewtype() >> is also a L<Type::Tiny> object,
so you can call any method from L<Type::Tiny>, such as
C<< MyNewtype->check( $value ) >> or C<< MyNewtype->coerce( $value ) >>.

=head2 Coercions

It is possible to include some coercion definitions when importing newtypes.

  use Types::Common 'Num';
  use Newtype
    DegC => {
      inner  => Num,
      coerce => [ DegF => sub { DegC( ( $_ - 32 ) / 1.8 ) } ],
    },
    DegF => {
      inner  => Num,
      coerce => [ DegC => sub { DegF( ( $_ * 1.8 ) + 32 ) } ],
    };
  
  # Both of these are 180 degrees Celsius.
  my $x1 = DegC( 180 );
  my $x2 = to_DegC( DegF( 356 ) );

The C<coerce> arrayref is a list of type-coderef pairs, suitable for passing
to C<add_type_coercions> from L<Type::Coercion>. Any strings used as types
are assumed to be other newtypes being defined in the same import.

=head1 EXAMPLES

=head2 Using newtypes instead of named parameters

Let's say you have a function like this:

  sub run_processes {
    my ( $runtime_processes, $startup_processes, $shutdown_processes ) = @_;
    $_->() for @$startup_processes;
    $_->() for @$runtime_processes;
    $_->() for @$shutdown_processes;
  }

This function takes three arrayrefs of coderefs. It's very easy for the
caller to forget what order to pass them in, and potentially pass them in
the wrong order.

Let's bring some newtypes into the mix:

  use feature 'state';
  use Types::Common qw( CodeRef, ArrayRef );
  use Type::Params qw( signature );
  use Newtype (
    StartupProcessList  => { inner => ArrayRef[CodeRef] },
    RuntimeProcessList  => { inner => ArrayRef[CodeRef] },
    ShutdownProcessList => { inner => ArrayRef[CodeRef] },
  );
  
  sub run_processes {
    state $sig = signature positional => [
      RuntimeProcessList->no_coercions,
      StartupProcessList->no_coercions,
      ShutdownProcessList->no_coercions,
    ];
    my ( $runtime_processes, $startup_processes, $shutdown_processes ) = &$sig;
    $_->() for @$startup_processes;
    $_->() for @$runtime_processes;
    $_->() for @$shutdown_processes;
  }

Now your function no longer accepts bare arrayrefs. Instead the caller needs
to convert their arrayrefs into your newtype. The need to call your function
like this:

  run_processes(
    RuntimeProcessList( \@coderefs1 ),
    StartupProcessList( \@coderefs2 ),
    ShutdownProcessList( \@coderefs3 ),
  );

If they try to pass the lists in the wrong order, they'll get a type constraint
error.

Exporting the C<RuntimeProcessList>, C<StartupProcessList>, and
C<ShutdownProcessList> functions to your caller is left as an exercise
for the reader!

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-newtype/issues>.

=head1 SEE ALSO

L<Type::Tiny::Class>, L<Subclass::Of>.

L<https://wiki.haskell.org/Newtype>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

