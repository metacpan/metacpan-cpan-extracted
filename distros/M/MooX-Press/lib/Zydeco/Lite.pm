use 5.008008;
use strict;
use warnings;

package Zydeco::Lite;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.075';

use MooX::Press ();
use Types::Standard qw( -types -is );

use Exporter::Shiny our @EXPORT = qw(
	app
	class role abstract_class interface
	generator
	method factory constant
	multi_method multi_factory
	before after around
	extends with has requires
	confess
	true false
	toolkit
	coerce
	overload
	version authority
	type_name
	begin end before_apply after_apply
);

use namespace::autoclean;

our %THIS;

sub _shift_type ($\@) {
	my ( $type, $ref ) = @_;
	return shift @$ref if @$ref && $type->check( $ref->[0] );
	return undef;
}

sub _pop_type ($\@) {
	my ( $type, $ref ) = @_;
	return pop @$ref if @$ref && $type->check( $ref->[-1] );
	return undef;
}

{
	my $app_count = 0;
	sub _anon_package_name {
		return sprintf( '%s::__ANON__::PKG%07d', __PACKAGE__, ++$app_count );
	}
}

sub _return_anon {
	my ( $kind, $nameref, $value ) = @_;
	
	return $value if is_Undef $nameref;
	
	if ( not is_Undef $$nameref ) {
		confess( '%s name expected to be string or reference to empty scalar variable', $kind );
	}
	
	$$nameref = $value;
	&Internals::SvREADONLY($nameref, 1);
	return;
}

sub true  () { !!1 }
sub false () { !!0 }

sub confess {
	require Carp;
	return Carp::confess( @_ > 1 ? sprintf( shift, @_ ) : $_[0] );
}

sub app {
	my $definition = _pop_type( CodeRef, @_ );
	my $name       = _shift_type( Str|ScalarRef, @_ );
	my %args       = @_;
	
	my $package;
	my $is_anon;
	if ( is_Str $name ) {
		$package = $name;
	}
	else {
		$is_anon = true;
		$package = _anon_package_name();
	}
	
	my $caller = caller;
	
	local $THIS{APP}      = $package;
	local $THIS{APP_SPEC} = {
		caller          => $caller,
		factory_package => $package,
		prefix          => $package,
		toolkit         => 'Moo',
		%args,
	};
	$definition->();
	
	if ( delete $args{debug} ) {
		require Data::Dumper;
		print STDERR Data::Dumper::Dumper( $THIS{APP_SPEC} );
	}
	
	'MooX::Press'->import(
		%{ $THIS{APP_SPEC} },
	);
	
	if ( $is_anon ) {
		@_ = ( app => $name, MooX::Press::make_absolute_package_name($package) );
		goto \&_return_anon;
	}
	return;
}

sub class {
	my $finalize = undef;
	if ( not $THIS{APP_SPEC} ) {
		my $caller = caller;
		$THIS{APP_SPEC} = {
			caller  => $caller,
			toolkit => 'Moo',
		};
		$finalize = sub {
			'MooX::Press'->import(
				%{ $THIS{APP_SPEC} },
			);
			$THIS{APP_SPEC} = undef;
		};
	}
	
	my $definition = _pop_type( CodeRef, @_ ) || sub { 1 };
	my $name       = ( @_ % 2 ) ? _shift_type( Str|ScalarRef, @_ ) : undef;
	my %args       = @_;

	my $kind =
		$args{interface}   ? 'interface' :
		$args{abstract}    ? 'abstract class' :
		$args{is_role}     ? 'role' :
		'class';
	
	if ( delete $args{is_generator} ) {
		my $gen = _wrap_generator( @_, $definition );
		
		if ( is_Str $name ) {
			my $key = sprintf(
				'%s:%s',
				$args{is_role} ? 'role_generator' : 'class_generator',
				$name,
			);
			$THIS{APP_SPEC}{$key} = $gen;
			$finalize->() if $finalize;
			return;
		}
		else {
			my $method  = $args{is_role} ? 'make_role_generator' : 'make_class_generator';
			my $package = _anon_package_name();
			'MooX::Press'->$method(
				MooX::Press::make_absolute_package_name($package),
				%{ $THIS{APP_SPEC} or {} },
				%args,
				generator => $gen,
			);
			
			@_ = ( "$kind generator", $name, MooX::Press::make_absolute_package_name($package) );
			goto \&_return_anon;
		}
	}
	
	my $key = sprintf(
		'%s:%s',
		$args{is_role} ? 'role' : 'class',
		is_Str($name) ? $name : '',
	);
	
	my $class_spec = do {
		local $THIS{CLASS} = is_Str($name) ? $name : undef;
		local $THIS{CLASS_SPEC} = { %args };
		$definition->();
		delete $THIS{CLASS_SPEC}{is_role};
		$THIS{CLASS_SPEC};
	};
	
	# Anonymous package
	if ( ! is_Str $name ) {
		my $method  = $args{is_role} ? 'make_role' : 'make_class';
		my $package = _anon_package_name();
		'MooX::Press'->$method(
			MooX::Press::make_absolute_package_name($package),
			%{ $THIS{APP_SPEC} or {} },
			%$class_spec,
		);
		@_ = ( $kind, $name, MooX::Press::make_absolute_package_name($package) );
		goto \&_return_anon;
	}
	# Nested class
	elsif ( $THIS{CLASS_SPEC} ) {
		defined $THIS{CLASS}
			or confess('cannot subclass anonymous classes');
		$THIS{CLASS_SPEC}{is_role}
			and confess('cannot subclass roles');
		$THIS{CLASS_SPEC}{is_generator}
			and confess('cannot subclass class generators');
		
		push @{ $THIS{CLASS_SPEC}{subclass} ||= [] }, $name, $class_spec;
	}
	# Otherwise
	else {
		$THIS{APP_SPEC}{$key} = $class_spec;
	}
	
	$finalize->() if $finalize;
	return;
}

sub role {
	$THIS{APP_SPEC}
		or confess("`role` used outside an app definition");
	
	my $definition = _pop_type( CodeRef, @_ ) || sub { 1 };
	push @_, ( is_role => true, $definition );
	goto \&class;
}

sub abstract_class {
	$THIS{APP_SPEC}
		or confess("`abstract_class` used outside an app definition");
	
	my $definition = _pop_type( CodeRef, @_ ) || sub { 1 };
	push @_, ( abstract => true, $definition );
	goto \&class;
}

sub interface {
	$THIS{APP_SPEC}
		or confess("`interface` used outside an app definition");
	
	my $definition = _pop_type( CodeRef, @_ ) || sub { 1 };
	push @_, ( interface => true, is_role => true, $definition );
	goto \&class;
}

sub _wrap_generator {
	my $definition = _pop_type( CodeRef, @_ );
	my %args       = @_;
	
	my $is_role    = delete $args{'is_role'};
	my $app        = $THIS{APP_SPEC};
	
	my $code = sub {
		local $THIS{APP_SPEC}   = $app;
		local $THIS{CLASS_SPEC} = { is_role => $is_role };
		$definition->(@_);
		delete $THIS{CLASS_SPEC}{is_role};
		return $THIS{CLASS_SPEC};
	};
	
	return { code => $code, %args };
}

sub generator {
	my $definition = _pop_type( CodeRef, @_ ) || sub { 1 };
	my $package    = _shift_type( Str|ScalarRef, @_ );
	my $sig        = _shift_type( Ref, @_ );
	my %args       = @_;
	
	return (
		$package ? $package : (),
		%args,
		is_generator => true,
		signature    => $sig,
		$definition,
	);
}

sub _method {
	my $next        = shift;
	my $definition  = _pop_type( CodeRef, @_ )
		or confess('methods must have a body');
	my $subname     = _shift_type( Str|ScalarRef, @_ );
	my $sig         = _shift_type( Ref, @_ );
	my %args        = @_;
	
	if ( is_ScalarRef $subname or is_Undef $subname ) {
		my $coderef;
		
		if ( $sig or keys %args ) {
			if ( defined $sig ) {
				$args{caller}    = caller;
				$args{code}      = $definition;
				$args{signature} = $sig;
				$args{named}     = false unless exists $args{named};
				
				$coderef = 'MooX::Press'->wrap_coderef( \%args );
			}
		}
		else {
			$coderef = $definition;
		}
		
		@_ = ( method => $subname, $coderef );
		goto &_return_anon;
	}
	
	$args{code}   = $definition;
	$args{caller} = caller;
	
	if ( defined $sig ) {
		$args{signature} = $sig;
		$args{named}     = false unless exists $args{named};
	}
	
	$next->( $subname, \%args );
	return;
}

sub method {
	my ( $target, $key ) = $THIS{CLASS_SPEC}
		? ( $THIS{CLASS_SPEC}, 'can' )
		: ( $THIS{APP_SPEC},   'factory_package_can' );
	my $next;
	
	if ( $target ) {
		$next = sub {
			my ( $subname, $args ) = @_;
			( $target->{$key} ||= {} )->{$subname} = $args;
		};
	}
	else {
		my $caller = caller;
		$next = sub {
			my ( $subname, $args ) = @_;
			'MooX::Press'->patch_package( $caller, can => { $subname => $args } );
		};
	}
	
	unshift @_, $next;
	goto \&_method;
}

sub multi_method {
	my $subname = is_Str($_[0])
		? $_[0]
		: confess('anonymous multi factories not supported');
	my $target = $THIS{CLASS_SPEC} || $THIS{APP_SPEC};
	my $next;
	
	if ( $target ) {
		$next = sub {
			my ( $subname, $args ) = @_;
			push @{ $target->{multimethod} ||= [] }, $subname, $args;
		};
	}
	else {
		my $caller = shift;
		$next = sub {
			my ( $subname, $args ) = @_;
			'MooX::Press'->patch_package( $caller, multimethod => { $subname => $args } );
		};
	}
	
	unshift @_, $next;
	goto \&_method;
}

sub factory {
	$THIS{CLASS_SPEC}
		or confess("`factory` used outside a class definition");
	$THIS{CLASS_SPEC}{is_role}
		and confess("`factory` used in a role definition");
	
	if ( @_==0 and not $THIS{CLASS_SPEC}{factory} ) {
		$THIS{CLASS_SPEC}{factory} = undef;
		return;
	}
	
	my $definition = _pop_type( CodeRef|ScalarRef, @_ );
	my $subnames   = _shift_type( Str|ArrayRef, @_ )
		or confess("factory cannot be anonymous");
	my $sig        = _shift_type( Ref, @_ );
	my %args       = @_;
	
	$subnames = [ $subnames ] if is_Str $subnames;
	$definition ||= \ "new";
	
	if ( ! is_ScalarRef $definition ) {
		my $code = $definition;
		$definition = \%args;
		$definition->{code}      = $code;
		$definition->{signature} = $sig if $sig;
	}
	
	push @{ $THIS{CLASS_SPEC}{factory} ||= [] }, @$subnames, $definition;
}

sub multi_factory {
	my $target = $THIS{CLASS_SPEC}
		or confess("`multi_factory` used outside a class definition");
	$target->{is_role}
		and confess("`multi_factory` used in a role definition");
	
	my $subname = is_Str($_[0])
		? $_[0]
		: confess('anonymous multi factories not supported');
	
	unshift @_, sub {
		my ( $subname, $args ) = @_;
		push @{ $target->{multifactory} ||= [] }, $subname, $args;
	};
	goto \&_method;
}

sub _modifier {
	my $modifier_type = shift;
	my $definition = _pop_type( CodeRef, @_ )
		or confess('methods modifiers must have a body');
	my $subname    = _shift_type( Str|ArrayRef, @_ )
		or confess("modified methods cannot be anonymous");
	my $sig        = _shift_type( Ref, @_ );
	my %args       = @_;
	
	$args{code} = $definition;
	
	if ( defined $sig ) {
		$args{signature} = $sig;
		$args{named}     = false unless exists $args{named};
	}
	
	my @keys = keys %args;
	if ( @keys > 1 ) {
		$definition = \%args;
	}
	
	my $target = $THIS{CLASS_SPEC} || $THIS{APP_SPEC};
	
	if ( $target ) {
		push @{ $target->{$modifier_type} ||= [] }, (
			ref($subname) ? @$subname : $subname,
			$definition,
		);
	}
	else {
		my $caller = caller;
		'MooX::Press'->patch_package( $caller, $modifier_type => { $subname => $definition } );
	}
	
	return;
}

sub before {
	unshift @_, 'before';
	goto \&_modifier;
}

sub after {
	unshift @_, 'after';
	goto \&_modifier;
}

sub around {
	unshift @_, 'around';
	goto \&_modifier;
}

sub extends {
	$THIS{CLASS_SPEC}
		or confess("`extends` used outside a class definition");
	$THIS{CLASS_SPEC}{is_role}
		and confess("`extends` used in a role definition");
	
	@{ $THIS{CLASS_SPEC}{extends} ||= [] } = @_;
	
	return;
}

sub with {
	$THIS{CLASS_SPEC}
		or confess("`with` used outside a class or role definition");
	
	push @{ $THIS{CLASS_SPEC}{with} ||= [] }, @_;
	
	return;
}

sub has {
	$THIS{CLASS_SPEC}
		or confess("`has` used outside a class or role definition");
	
	my $names = _shift_type( ArrayRef|ScalarRef|Str, @_ )
		or confess("attributes cannot be anonymous");
	my $spec  = @_ == 1 ? $_[0] : { @_ };
	
	$names = [ $names ] unless is_ArrayRef $names;
	push @{ $THIS{CLASS_SPEC}{has} ||= [] }, ( $_, $spec ) for @$names;
	
	return;
}

sub constant {
	my $names = _shift_type( ArrayRef|Str, @_ )
		or confess("constants cannot be anonymous");
	my $value  = shift;
	
	$names = [ $names ] unless is_ArrayRef $names;
	
	if ( $THIS{CLASS_SPEC} ) {
		( $THIS{CLASS_SPEC}{constant} ||= {} )->{$_} = $value for @$names;
	}
	else {
		my $caller = caller;
		my %constants;
		$constants{$_} = $value for @$names;
		'MooX::Press'->patch_package( $caller, constant => \%constants );
	}
	
	return;
}

sub requires {
	$THIS{CLASS_SPEC} && $THIS{CLASS_SPEC}{is_role}
		or confess("`requires` used outside a role definition");
	
	#TODO: handle signatures
	my ( @subnames ) = @_;
	
	push @{ $THIS{CLASS_SPEC}{requires} ||= [] }, @subnames;
	
	return;
}

sub toolkit {
	my $target = $THIS{CLASS_SPEC} || $THIS{APP_SPEC}
		or confess('`toolkit` used outside app, class, or role definition');
	
	my ( $toolkit, @imports ) = @_;
	confess('no toolkit given') unless $toolkit;
	
	$target->{toolkit} = $toolkit;
	push @{ $target->{import} ||= [] }, map {
		/^::(.+)/ ? $1 : "${toolkit}X::$_";
	} @imports;
	
	return;
}

sub type_name {
	$THIS{CLASS_SPEC}
		or confess("`type_name` used outside a class or role definition");
	
	@_==1 && ( Str|Undef )->check( $_[0] )
		or confess("expected type name");
	
	$THIS{CLASS_SPEC}{type_name} = shift;
	
	return;
}

sub version {
	my $target = $THIS{CLASS_SPEC} || $THIS{APP_SPEC}
		or confess("`version` used outside app, class, or role definition");
	$target->{version} = shift;
	return;
}

sub authority {
	my $target = $THIS{CLASS_SPEC} || $THIS{APP_SPEC}
		or confess("`authority` used outside app, class, or role definition");
	$target->{authority} = shift;
	return;
}

sub overload {
	$THIS{CLASS_SPEC}
		or confess("`overload` used outside a class");
	$THIS{CLASS_SPEC}{is_role}
		and confess("`overload` used in a role definition");
	
	my %overload = @_;
	
	$THIS{CLASS_SPEC}{overload} = +{
		%{ $THIS{CLASS_SPEC}{overload} or {} },
		%overload,
	};
	
	return;
}

sub coerce {
	$THIS{CLASS_SPEC}
		or confess("`coerce` used outside a class or role");
	
	my $type   = _shift_type( Str|Object, @_ )
		or confess("expected type to coerce from");
	my $method = _shift_type( Str, @_ )
		or confess("expected method name to coerce via");
	my $code   = _shift_type( CodeRef, @_ );
	
	push @{ $THIS{CLASS_SPEC}{coerce} ||= [] }, (
		$type,
		$method,
		$code ? $code : (),
	);
	
	return;
}

sub _handle_hook {
	my $package = $THIS{CLASS};
	my %spec    = %{ $THIS{CLASS_SPEC} };
	
	my %remains = 'MooX::Press'->patch_package(
		$package,
		%spec,
	);
	confess( 'bad stuff in %s hook', $THIS{HOOK} )
		if keys %remains;
	
	return;

}

sub begin (&) {
	$THIS{CLASS_SPEC}
		or confess("`begin` used outside a class or role definition");
	
	is_CodeRef( my $coderef = shift ) or confess('expected coderef');
	
	push @{ $THIS{CLASS_SPEC}{begin} ||= [] }, sub {
		local $THIS{CLASS}      = $_[0];
		local $THIS{CLASS_SPEC} = {};
		local $THIS{HOOK}       = 'begin';
		$coderef->(@_);
		return _handle_hook(@_);
	};
	
	return;
}

sub end (&) {
	$THIS{CLASS_SPEC}
		or confess("`end` used outside a class or role definition");
	
	is_CodeRef( my $coderef = shift ) or confess('expected coderef');
	
	push @{ $THIS{CLASS_SPEC}{end} ||= [] }, sub {
		local $THIS{CLASS}      = $_[0];
		local $THIS{CLASS_SPEC} = {};
		local $THIS{HOOK}       = 'end';
		$coderef->(@_);
		return _handle_hook(@_);
	};
	
	return;
}

sub before_apply (&) {
	$THIS{CLASS_SPEC} && $THIS{CLASS_SPEC}{is_role}
		or confess("`before_apply` used outside a class or role definition");
	
	is_CodeRef( my $coderef = shift ) or confess('expected coderef');
	
	require Role::Hooks;
	push @{ $THIS{CLASS_SPEC}{before_apply} ||= [] }, sub {
		local $THIS{CLASS}      = $_[1];
		local $THIS{CLASS_SPEC} = {};
		local $THIS{HOOK}       = 'before_apply';
		my $kind = 'Role::Hooks'->is_role($_[1]) ? 'role' : 'class';
		$coderef->(@_, $kind);
		return _handle_hook(@_);
	};
	
	return;
}

sub after_apply (&) {
	$THIS{CLASS_SPEC} && $THIS{CLASS_SPEC}{is_role}
		or confess("`after_apply` used outside a class or role definition");
	
	is_CodeRef( my $coderef = shift ) or confess('expected coderef');
	
	require Role::Hooks;
	push @{ $THIS{CLASS_SPEC}{after_apply} ||= [] }, sub {
		local $THIS{CLASS}      = $_[1];
		local $THIS{CLASS_SPEC} = {};
		local $THIS{HOOK}       = 'after_apply';
		my $kind = 'Role::Hooks'->is_role($_[1]) ? 'role' : 'class';
		$coderef->(@_, $kind);
		return _handle_hook(@_);
	};
	
	return;
}

true;

__END__

=pod

=encoding utf-8

=head1 NAME

Zydeco::Lite - Zydeco without any magic

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Zydeco::Lite;
  
  app "Local::MyApp" => sub {
    
    role "Greeting" => sub {
      
      method "greeting" => sub {
        return "Hello";
      };
    };
    
    role generator "Location" => [ "Str" ] => sub {
      my ( $gen, $arg ) = @_;
      
      method "location" => sub {
        return $arg;
      };
    };
    
    class "Hello::World" => sub {
      with "Greeting";
      with "Location" => [ "world" ];
      
      method "do_it" => [] => sub {
        my $self = shift;
        print $self->greeting, " ", $self->location, "\n";
      };
    };
  };
  
  my $obj = "Local::MyApp""->new_hello_world;
  $obj->do_it();

=head1 DESCRIPTION

L<Zydeco::Lite> is a L<Zydeco>-like module, but without using any parsing
tricks. Zydeco requires Perl 5.14 or above, but Zydeco::Lite will run on
any version of Perl since 5.8.8.

It's intended to be a happy medium between L<Zydeco> and L<MooX::Press>.

=head2 Syntax Examples

=head3 Apps

Apps:

  app "MyApp" => sub {
    # definition
  };

Anonymous apps:

  my $app = app sub {
    # definition
  };
  
  app \(my $app) => sub {
    # definition
  };

As of Zydeco::Lite 0.69, classes and roles no longer need to be defined
within an C<< app >> block, but bundling them into an app block has the
advantage that the app is able to define all its classes and roles
together, cross-referencing them, and setting them up in a sensible order.
(Which becomes important if you define a role after defining a class that
consumes it.)

=head3 Classes, Roles, Interfaces, and Abstract Classes

Classes:

  class "MyClass" => sub {
    # definition
  };

Anonymous classes:

  my $class = class sub {
    # definition
  };
  
  my $obj = $class->new();

  class \(my $class) => sub {
    # definition
  };
  
  my $obj = $class->new();

Class generators:

  class generator "MyGen" => sub {
    my ( $gen, @args ) = ( shift, @_ );
    # definition
  };
  
  my $class = $app->generate_mygen( @args );
  my $obj   = $class->new();

  class generator "MyGen" => [ @signature ] => sub {
    my ( $gen, @args ) = ( shift, @_ );
    # definition
  };

Anonymous class generators:

  my $gen = class generator sub {
    my ( $gen, @args ) = ( shift, @_ );
    # definition
  };
  
  my $class = $gen->generate_package( @args );
  my $obj   = $class->new();

  class generator \(my $gen) => sub {
    my ( $gen, @args ) = ( shift, @_ );
    # definition
  };
  
  my $class = $gen->generate_package( @args );
  my $obj   = $class->new();

Roles, interfaces, and abstract classes work the same as classes, but use
keywords C<role>, C<interface>, and C<abstract_class>.

Inheritance:

  class "Base" => sub { };
  
  class "Derived" => sub {
    extends "Base";
  };

Inheritance using nested classes:

  class "Base" => sub {
    ...;
    
    class "Derived" => sub {
      ...;
    };
  };

Inheriting from a generated class:

  class generator "Base" => sub {
    my ( $gen, @args ) = ( shift, @_ );
    ...;
  };
  
  class "Derived" => sub {
    extends "Base" => [ @args ];
  };

Composition:

  role "Named" => sub {
    requires "name";
  };
  
  class "Thing" => sub {
    with "Named";
    has "name" => ();
  };

Composing an anonymous role:

  class "Thing" => sub {
    with role sub {
      requires "name";
    };
    
    has "name" => ();
  };

Composing a generated role:

  role generator "Thingy" => sub {
    my ( $gen, @args ) = ( shift, @_ );
    ...;
  };
  
  class "Derived" => sub {
    with "Thingy" => [ @args ];
  };

=head3 Package Settings

Class version:

  class "Foo" => sub {
    version "1.000";
  };

  class "Foo" => ( version => "1.0" )
              => sub {
    ...;
  };

Class authority:

  class "Foo" => sub {
    authority "cpan:TOBYINK";
  };

  class "Foo" => ( version => "1.0", authority => "cpan:TOBYINK" )
              => sub {
    ...;
  };

Using non-Moo toolkits:

  class "Foo" => sub {
    toolkit "Mouse";
  };

  class "Bat" => sub {
    toolkit "Moose" => ( "StrictConstructor" );
  };

The C<version>, C<authority>, and C<toolkit> keywords can be used within
C<app>, C<class>, C<role>, C<interface>, or C<abstract_class> definitions.

=head3 Attributes

Attributes:

  has "myattr" => ( ... );
  
  has [ "myattr1", "myattr2" ] => ( ... );

Private attributes:

  has "myattr" => ( is => "private", ..., accessor => \(my $accessor) );

=head3 Methods

Methods:

  method "mymeth" => sub {
    my ( $self, @args ) = ( shift, @_ );
    ...;
  };

Methods with positional signatures:

  method "mymeth" => [ 'Num', 'Str' ]
                  => sub
  {
    my ( $self, $age, $name ) = ( shift, @_ );
    ...;
  };

Methods with named signatures:

  method "mymeth" => [ age => 'Num', name => 'Str' ]
                  => ( named => 1 )
                  => sub
  {
    my ( $self, $args ) = ( shift, @_ );
    ...;
  };

Anonymous methods:

  my $mymeth = method sub {
    my ( $self, @args ) = ( shift, @_ );
    ...;
  }

  method \(my $mymeth) => sub {
    my ( $self, @args ) = ( shift, @_ );
    ...;
  }

Anonymous methods may have signatures.

Required methods in roles:

  requires "method1", "method2";
  requires "method3";

Method modifiers:

  before "somemethod" => sub {
    my ( $self, @args ) = ( shift, @_ );
    ...;
  };

  after [ "method1", "method2"] => sub {
    my ( $self, @args ) = ( shift, @_ );
    ...;
  };

  around "another" => sub {
    my ( $next, $self, @args ) = ( shift, shift, @_ );
    ...;
    $self->$next( @_ );
    ...;
  };

Constants:

  constant "ANSWER_TO_LIFE" => 42;

Overloading:

  method "to_string" => sub {
    my $self = shift;
    ...;
  };
  
  overload(
    q[""]    => "to_string",
    fallback => 1,
  );

Factory methods:

  factory "new_foo" => \"new";

  factory "new_foo" => sub {
    my ( $factory, $class, @args ) = ( shift, shift, @_ );
    return $class->new( @args );
  };

Factory methods may include signatures like methods.

Indicate you want a class to have no factories:

  factory();

The keywords C<multi_method> and C<multi_factory> exist for multimethods.

=head3 Types

Setting the type name for a class or role:

  class "Foo::Bar" => sub {
    type_name "Foobar";
     ...;
  };

Coercion:

  class "Foo::Bar" => sub {
    method "from_arrayref" => sub {
      my ( $class, $aref ) = ( shift, @_ );
      ...;
    };
    coerce "ArrayRef" => "from_arrayref";
  };

  class "Foo::Bar" => sub {
    coerce "ArrayRef" => "from_arrayref" => sub {
      my ( $class, $aref ) = @_;
      ...;
    };
  };

=head3 Hooks

Hooks for classes:

  begin {
    my ( $class ) = ( shift );
    # Code that runs early during class definition
  };

  end {
    my ( $class ) = ( shift );
    # Code that runs late during class definition
  };

Hooks for roles:

  begin {
    my ( $role ) = ( shift );
    # Code that runs early during role definition
  };

  end {
    my ( $role ) = ( shift );
    # Code that runs late during role definition
  };

  before_apply {
    my ( $role, $target, $targetkind ) = ( shift, @_ );
    # Code that runs before a role is applied to a package
  };

  after_apply {
    my ( $role, $target, $targetkind ) = ( shift, @_ );
    # Code that runs after a role is applied to a package
  };

=head3 Utilities

Booleans:

  my $truth = true;
  my $truth = false;

Exceptions:

  confess( 'Something bad happened' );
  confess( 'Exceeded maximum (%d)', $max );

=head2 Formal Syntax

Scope B<ANY> means the keyword can appear anywhere where Zydeco::Lite
is in scope. Scope B<CLASS> means that the keyword may appear only within
class or abstract class definition blocks. Scope B<ROLE> means that the
keyword may appear only in role/interface definition blocks. Scope B<APP>
means that the keyword may appear only within an app definition block.

 # Scope: ANY
 app(
   Optional[Str|ScalarRef]  $name,
   Hash                     %args,
   Optional[CodeRef]        $definition,
 );
 
 # Scope: ANY
 class(
   Optional[Str|ScalarRef]  $name,
   Hash                     %args,
   Optional[CodeRef]        $definition,
 );
 
 # Scope: ANY
 class generator(
   Optional[Str|ScalarRef]  $name,
   Optional[ArrayRef]       $signature,
   Hash                     %args,
   Optional[CodeRef]        $definition,
 );
 
 # Scope: ANY
 role(
   Optional[Str|ScalarRef]  $name,
   Hash                     %args,
   Optional[CodeRef]        $definition,
 );
 
 # Scope: ANY
 role generator(
   Optional[Str|ScalarRef]  $name,
   Optional[ArrayRef]       $signature,
   Hash                     %args,
   Optional[CodeRef]        $definition,
 );
 
 # Scope: ANY
 interface(
   Optional[Str|ScalarRef]  $name,
   Hash                     %args,
   Optional[CodeRef]        $definition,
 );
 
 # Scope: ANY
 interface generator(
   Optional[Str|ScalarRef]  $name,
   Optional[ArrayRef]       $signature,
   Hash                     %args,
   Optional[CodeRef]        $definition,
 );
 
 # Scope: ANY
 abstract_class(
   Optional[Str|ScalarRef]  $name,
   Hash                     %args,
   Optional[CodeRef]        $definition,
 );
 
 # Scope: ANY
 abstract_class generator(
   Optional[Str|ScalarRef]  $name,
   Optional[ArrayRef]       $signature,
   Hash                     %args,
   Optional[CodeRef]        $definition,
 );
 
 # Scope: CLASS
 extends(
   List[Str|ArrayRef]       @parents,
 );
 
 # Scope: CLASS or ROLE
 with(
   List[Str|ArrayRef]       @parents,
 );
 
 # Scope: ANY
 method(
   Optional[Str|ScalarRef]  $name,
   Optional[ArrayRef]       $signature,
   Hash                     %args,
   CodeRef                  $body,
 );
 
 # Scope: CLASS
 factory(
   Str|ArrayRef             $names,
   Optional[ArrayRef]       $signature,
   Hash                     %args,
   CodeRef|ScalarRef        $body_or_via,
 );
 
 # Scope: ANY
 constant(
   Str|ArrayRef             $names,
   Any                      $value,
 );
 
 # Scope: ANY
 multi_method(
   Str                      $name,
   ArrayRef                 $signature,
   Hash                     %args,
   CodeRef                  $body,
 );
 
 # Scope: CLASS
 multi_factory(
   Str                      $name,
   ArrayRef                 $signature,
   Hash                     %args,
   CodeRef                  $body,
 );
 
 # Scope: ANY
 before(
   Str|ArrayRef             $names,
   Optional[ArrayRef]       $signature,
   Hash                     %args,
   CodeRef                  $body,
 );
 
 # Scope: ANY
 after(
   Str|ArrayRef             $names,
   Optional[ArrayRef]       $signature,
   Hash                     %args,
   CodeRef                  $body,
 );
 
 # Scope: ANY
 around(
   Str|ArrayRef             $names,
   Optional[ArrayRef]       $signature,
   Hash                     %args,
   CodeRef                  $body,
 );
 
 # Scope: CLASS or ROLE
 has(
   Str|ArrayRef             $names,
   Hash|HashRef|ArrayRef    %spec,
 );
 
 # Scope: ROLE
 requires(
   List[Str]                @names,
 );
 
 # Scope: ANY
 confess(
   Str                      $template,
   List                     @args,
 );
 
 # Scope: APP or CLASS or ROLE
 toolkit(
   Str                      $toolkit,
   Optional[List]           @imports,
 );
 
 # Scope: CLASS or ROLE
 coerce(
   Object|Str               $type,
   Str                      $via,
   Optional[CodeRef]        $definition,
 );
 
 # Scope: CLASS
 overload(
   Hash                     %args,
 );
 
 # Scope: APP or CLASS or ROLE
 version(
   Str                      $version,
 );
 
 # Scope: APP or CLASS or ROLE
 authority(
   Str                      $authority,
 );
 
 # Scope: CLASS or ROLE
 type_name(
   Str                      $name,
 );
 
 # Scope: CLASS or ROLE
 begin {
   my ( $package ) = @_;
   ...;
 };
 
 # Scope: CLASS or ROLE
 end {
   my ( $package ) = @_;
   ...;
 };
 
 # Scope: ROLE
 before_apply {
   my ( $role, $target, $targetkind ) = @_;
   ...;
 };
 
 # Scope: ROLE
 after_apply {
   my ( $role, $target, $targetkind ) = @_;
   ...;
 };

Scopes are dynamic rather than lexical. So although C<extends> can only appear
in a B<CLASS>, this will work:

 use Zydeco::Lite;
 
 class "Base";
 
 sub foo { extends "Base" }
 
 class "Derived" => sub { foo() };

Keywords used within a C<before_apply> or C<after_apply> block execute in the
scope of the package they're being applied to. They run too late for
C<type_name> to work, but most other keywords will work okay. In the following
example, Derived will be a child class of Base.

 use Zydeco::Lite;
 
 class "Base";
 
 role "ChildOfBase" => sub {
   after_apply {
     my ( $role, $target, $kind ) = @_;
     extends "Base" if $kind eq "class";
   };
 };
 
 class "Derived" => sub {
   with "ChildOfBase";
 };

=head2 Import

Zydeco::Lite uses L<Exporter::Tiny>, so you can choose which keywords
to import, rename them, etc.

  use Zydeco::Lite { -prefix => 'zy_' };
  
  my $app = zy_app {
    zy_class 'Foo' => sub {};
  };
  
  my $obj = $app->new_foo();

=head1 EXAMPLE

   package Zoo;
   use strict;
   use warnings;
   use Zydeco::Lite;
   
   my $app = __PACKAGE__;
   
   app $app => sub {
      
      class 'Park' => sub {
         
         has 'name' => (
            type        => 'Str',
         );
         
         has 'animals' => (
            type        => 'ArrayRef',
            default     => sub { [] },
            handles_via => 'Array',
            handles     => [
               'add_animal' => 'push',
               'list_animals' => 'all',
            ],
         );
         
         method 'print_animals' => [] => sub {
            my ( $self ) = ( shift );
            for my $animal ( $self->list_animals ) {
               $animal->print_animal;
            }
         };
      };
      
      role generator 'Animal' => [ 'Str' ] => sub {
         my ( $gen, $species ) = ( shift, @_ );
         
         has 'name' => ( type => 'Str', required => true );
         
         method 'print_animal' => [] => sub {
            my ( $self ) = ( shift );
            printf( "%s (%s)\n", $self->name, $species );
         };
      };
      
      class 'Lion' => sub {
         with 'Animal' => [ 'Panthera leo' ];
      };
      
      class 'Tiger' => sub {
         with 'Animal' => [ 'Panthera tigris' ];
      };
      
      class 'Bear' => sub {
         with 'Animal' => [ 'Ursus arctos' ];
      };
   };
   
   my $zoo = $app->new_park( name => "Oz Zoo" );
   $zoo->add_animal( $app->new_lion( name => "Simba" ) );
   $zoo->add_animal( $app->new_lion( name => "Aslan" ) );
   $zoo->add_animal( $app->new_tiger( name => "Tigger" ) );
   $zoo->add_animal( $app->new_tiger( name => "Shere Khan" ) );
   $zoo->add_animal( $app->new_bear( name => "Paddington" ) );
   $zoo->add_animal( $app->new_bear( name => "Yogi" ) );
   $zoo->print_animals; # oh my!

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-Press>.

=head1 SEE ALSO

L<Zydeco>, L<MooX::Press>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

