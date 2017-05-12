use strict;

package Salvation::Service;

use Moose;

with 'Salvation::Roles::AppArgs', 'Salvation::Roles::DataSet', 'Salvation::Roles::SharedStorage', 'Salvation::Roles::SystemReference', 'Salvation::Roles::ServiceState';

use Salvation::Stuff ( '&load_class', '&full_pkg' );

use Digest::MD5 '&md5_hex';

foreach my $name ( ( 'model', 'view', 'controller' ) )
{
	my $ucfirst = ucfirst( $name );

	has $name => ( is => 'ro', isa => 'Maybe[Salvation::Service::' . $ucfirst . ']', lazy => 1, init_arg => undef, default => sub{ return shift -> __build_infrastructure_reference( substr( $ucfirst, 0, 1 ) ); } );
}

has 'output_processor' => ( is => 'ro', isa => 'Maybe[Salvation::Service::OutputProcessor]', lazy => 1, init_arg => undef, default => sub
{
	my $self = shift;

	return $self -> __build_infrastructure_reference( 'OutputProcessor' => ( system => $self -> system(), state => $self -> state() ) );
} );

has '__nohook'	=> ( is => 'ro', isa => 'Bool', default => 0, lazy => 1 );

has 'hook'	=> ( is => 'ro', isa => 'Maybe[Salvation::Service::Hook]', lazy => 1, builder => '_build_hook', predicate => 'has_hook' );

has '__hooks'	=> ( is => 'rw', isa => 'ArrayRef[ArrayRef[ArrayRef[Defined]]]', lazy => 1, default => sub{ [] } ); # Hooklist => Speclist => Spec

has '__controller_methods'	=> ( is => 'rw', isa => 'ArrayRef[ArrayRef[Defined]]', lazy => 1, default => sub{ [] } ); # Speclist => Spec

sub RERUN_ON_BAD_HOOK { 1 }

sub intent
{
	my ( $self, $service ) = @_;

	require Salvation::Service::Intent;

	return Salvation::Service::Intent -> new(
		service => $service,
		( map{ $_ => $self -> $_() } ( 'args', 'dataset', 'storage', 'system', 'state' ) )
	);
}

sub Hook
{
	my ( $self, @list ) = @_;

	push @{ $self -> __hooks() }, \@list;

	return 1;
}

sub Call
{
	my ( $self, @list ) = @_;

	push @{ $self -> __controller_methods() }, \@list;

	return 1;
}

sub __get_hook
{
	my $self   = shift;
	my $result = '';

SCAN_HOOK_LIST:
	foreach my $list ( @{ $self -> __hooks() } )
	{
		my @path = ();

		foreach my $spec ( @$list )
		{
			my ( $value, $type, $flags ) = @$spec;

			$flags ||= {};

			if( ref( my $code = $flags -> { 'transform_value' } ) eq 'CODE' )
			{
				$value = $code -> ( $self, $value, $type );
			}

			if( ref( my $code = $flags -> { 'transform_type' } ) eq 'CODE' )
			{
				$type = $code -> ( $self, $value, $type );
			}

			if( ref( my $code = $flags -> { 'transform_value_and_type' } ) eq 'CODE' )
			{
				( $value, $type ) = $code -> ( $self, $value, $type );
			}

			my $ok = 1;

			if( ref( my $code = $flags -> { 'constraint' } ) eq 'CODE' )
			{
				$ok = $code -> ( $self, $value, $type );
			}

			if( $value and $type and $ok )
			{
				push @path, $type, $value;
			} else
			{
				next SCAN_HOOK_LIST;
			}
		}

		if( scalar @path )
		{
			if( $self -> __load_hook( $result = &full_pkg( @path ) ) )
			{
				last SCAN_HOOK_LIST;

			} else
			{
				if( my $err = $@ )
				{
					$self -> system() -> on_hook_load_error( {
						'$@'     => $err,
						hook     => $result,
						service  => ( ref( $self ) or $self ),
						instance => $self
					} );
				}

				$result = '';
			}
		}
	}

	return $result;
}

sub __run_controller_methods
{
	my $self = shift;

	foreach my $spec ( @{ $self -> __controller_methods() } )
	{
		last if $self -> state() -> stopped();

		my ( $method, $flags ) = @$spec;

		$flags ||= {};

		if( ref( my $code = $flags -> { 'transform_method' } ) eq 'CODE' )
		{
			$method = $code -> ( $self, $method );
		}

		my $ok = 1;

		if( ref( my $code = $flags -> { 'constraint' } ) eq 'CODE' )
		{
			$ok = $code -> ( $self, $method );
		}

		if( $method and $ok )
		{
			my @args = ();

			if( ref( my $args = $flags -> { 'args' } ) eq 'ARRAY' )
			{
				@args = @$args;
			}

			$self -> __safecall( 'controller', sub{ shift -> $method( @args ) } );

			if( my $err = $self -> storage() -> get( '$@' ) )
			{
				$self -> system() -> on_service_controller_method_error( {
					service  => ( ref( $self ) or $self ),
					instance => $self,
					'$@'     => $err,
					method   => $method
				} );

				if( $flags -> { 'fatal' } )
				{
					$self -> state() -> stop();
				}
			}
		}
	}

	return 1;
}

sub __full_hook_pkg
{
	my ( $self, $pkg, $orig ) = @_;

	return return &full_pkg( ( $orig or ref( $self ) ), 'Hooks', $pkg );
}

sub __full_default_pkg
{
	my ( $self, $pkg, $orig ) = @_;

	return &full_pkg( ( $orig or ref( $self ) ), 'Defaults', $pkg );
}

sub __load_hook
{
	my ( $self, $pkg, $orig ) = @_;

	return &load_class( $self -> __full_hook_pkg( $pkg, $orig ) );
}

sub __associate_with_hook
{
	my ( $self, $hook ) = @_;

	$hook -> __associated_service( $self );

	return 1;
}

sub _build_hook
{
	my $self     = shift;
	my $instance = undef;

	if( not( $self -> __nohook() ) and ( my $hook = $self -> __get_hook() ) )
	{
		if( $instance = eval{ $self -> intent( $self -> __full_hook_pkg( $hook ) ) -> service() } )
		{
			$self -> __associate_with_hook( $instance );

			if( my $lhook = $instance -> hook() )
			{
				$instance = $lhook;
			}
		}
	}

	return $instance;
}

sub __build_infrastructure_reference
{
	my ( $self, $suffix, @rest ) = @_;

	my $pkg = '';

	if( my $hook = $self -> hook() )
	{
		my $sref = ref( $self );

		while( $hook )
		{
			last if
				$pkg = $self -> __try_to_load_infrastructure_package( $suffix, $sref, ref( $hook ) );

			$hook = $hook -> __parent_link();
		}
	}

	$pkg ||= $self -> __full_default_pkg( $suffix );

	return ( &load_class( $pkg ) ? $pkg -> new( ( scalar( @rest ) ? @rest : ( service => $self ) ) ) : undef );
}

sub __try_to_load_infrastructure_package
{
	my ( $self, $suffix, $sref, $href ) = @_;

	my $pkg = '';

	$href =~ s/^$sref\:\://;

	unless( &load_class( $pkg = &full_pkg( $sref, $self -> __full_default_pkg( $suffix, $href ) ) ) )
	{
		$pkg = '';
	}

	return $pkg;
}

sub cacheid
{
	# this function can be redefined
	return '';
}

sub __cacheid
{
	my $self = shift;

	return &md5_hex( join( '_',
		ref( $self ),
		( $self -> has_hook() ? ( ref( $self -> hook() ) ) : () ),
		$self -> cacheid(),
		@_
	) );
}

sub __safecall
{
	my $wa = wantarray;
	my ( $self, $method, $code ) = @_;

	my $out = undef;
	my @out = ();

	eval
	{
		if( my $obj = $self -> $method() )
		{
			if( $wa )
			{
				@out = $code -> ( $obj );
			} else
			{
				$out = $code -> ( $obj );
			}
		}
	};

	if( my $err = $@ )
	{
		$self -> storage() -> put( '$@', $err );
	}

	return ( $wa ? @out : $out );
}

sub throw
{
	my ( $self, @rest ) = @_;

	if( my $err = $self -> storage() -> get( '$@' ) )
	{
		push @rest, ( 'Previous error:' => $err );
	}

	$self -> storage() -> put( '$@', \@rest );
	$self -> state() -> stop();

	goto STOPPED_VIA_THROW; # EVILNESS

	return 1;
}

sub __wrap_with_a_method_from_hook_and_call
{
	my ( $self, $code, @args ) = @_;

	if( my $hook = $self -> hook() )
	{
		return $hook -> $code( @args );
	}

	return $self -> $code( @args );
}

sub start
{
	my $self = shift;

	return 1 if $self -> state() -> stopped();

	my $aux = sub{ return $self -> __safecall( 'controller', shift ); };

	$self -> __wrap_with_a_method_from_hook_and_call( sub{ shift -> init( @_ ) } );	# service -> init

	return 2 if $self -> state() -> stopped();

	$aux -> ( sub{ shift -> init() } );	# controller -> init

	return 3 if $self -> state() -> stopped();

	$self -> __run_controller_methods(); # scheduled controller methods

	return 4 if $self -> state() -> stopped();

	$self -> __wrap_with_a_method_from_hook_and_call( sub{ shift -> main( @_ ) } );	# service -> main

	return 5 if $self -> state() -> stopped();

	$aux -> ( sub{ shift -> main() } );	# controller -> main

	return 6 if $self -> state() -> stopped();

	unless( $self -> state() -> need_to_skip_view() )
	{
		$aux -> ( sub{ shift -> before_view_processing() } );	# controller -> before_view_processing

		return 7 if $self -> state() -> stopped();

		$self -> __safecall( 'view', sub{ shift -> process() } );	# view -> process

		return 8 if $self -> state() -> stopped();

		$aux -> ( sub{ shift -> after_view_processing() } );	# controller -> after_view_processing
	}

	return 9 if $self -> state() -> stopped();

	return 0;

STOPPED_VIA_THROW:
	return 10;
}

sub main
{
}

sub init
{
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

# ABSTRACT: Base class for a service

=pod

=head1 NAME

Salvation::Service - Base class for a service

=head1 SYNOPSIS

 package YourSystem::Services::SomeService;

 use Moose;

 extends 'Salvation::Service';

 no Moose;

=head1 REQUIRES

L<Digest::MD5> 

L<Moose> 

=head1 DESCRIPTION

=head2 Applied roles

L<Salvation::Roles::AppArgs>

L<Salvation::Roles::DataSet>

L<Salvation::Roles::SharedStorage>

L<Salvation::Roles::SystemReference>

L<Salvation::Roles::ServiceState>

=head1 METHODS

=head2 To be called

=head3 system

 $service -> system()

Return appropriate L<Salvation::System>-derived object instance.

=head3 model

 $service -> model();

Return appropriate L<Salvation::Service::Model>-derived object instance.

=head3 view

 $service -> view();

Return appropriate L<Salvation::Service::View>-derived object instance.

=head3 controller

 $service -> controller();

Return appropriate L<Salvation::Service::Controller>-derived object instance.

=head3 output_processor

 $service -> output_processor();

Return appropriate L<Salvation::Service::OutputProcessor>-derived object instance.

=head3 hook

 $service -> hook();

Return appropriate L<Salvation::Service::Hook>-derived object instance. Normally you should not want to call this method directly.

=head3 Call

 $self -> Call( $name );
 $self -> Call( $name, \%flags );

Add a method with C<$name> to the list of controller methods.
Each and every method from this list will be called at appropriate stage of the execution flow.

You can use C<\%flags> to do some tweaking providing following keys:

=over

=item transform_method

A CodeRef which will be called in order to change method's name.

 transform_method => sub
 {
 	my ( $service_instance, $method_name ) = @_;

	$method_name = 'A' if $method_name eq 'B';

 	return $method_name;
 }

Useful when you feel especially crutchy.

=item constraint

A CodeRef which will be called in order to check whether the method needs to be called, or not. Should return boolean value.

 constraint => sub
 {
 	my ( $service_instance, $method_name ) = @_;

 	return ( int( rand( 2 ) ) == 1 );
 }

=item args

An ArrayRef of method arguments.

=item fatal

A boolean value. When this value is true and the method fails - the service will be interrupted.

=back

=head3 Hook

 $self -> Hook( [ $value, $type ], ... );
 $self -> Hook( [ $value, $type, \%flags ], ... );

Adds a hook spec to the list.

Hook name will be generated somehow like this:

 sprintf(
 	'%s::Hooks::%s::%s',
	ref( $self ),
	$type,
	$value
 )

You can use C<\%flags> to do some tweaking providing following keys:

=over

=item transform_value

A CodeRef which will be called in order to change C<$value>.

 transform_value => sub
 {
 	my ( $service_instance, $value, $type ) = @_;

	$value = not $value if $type eq not $type;

	return $value;
 }

=item transform_type

A CodeRef which will be called in order to change C<$type>.

 transform_type => sub
 {
 	my ( $service_instance, $value, $type ) = @_;

	$type = 'Generic' if $type eq 'Specific';

	return $type;
 }

=item transform_value_and_type

A CodeRef which will be called in order to change both C<$value> and C<$type>.

 transform_value_and_type => sub
 {
 	my ( $service_instance, $value, $type ) = @_;

	$value ^= ( $type ^= ( $value ^= $type ) );

	return ( $value, $type );
 }

Because why not?

=item constraint

A CodeRef which will be called in order to check whether the hook needs to be used, or not. Should return boolean value.

 constraint => sub
 {
 	my ( $service_instance, $value, $type ) = @_;

	return ( int( rand( 2 ) ) == 1 );
 }

=back

=head3 intent

 $self -> intent( $full_package_name );

Returns new L<Salvation::Service::Intent> object intended to run C<$full_package_name> service within the same environment and with the same DataSet as current service.

=head3 throw

 $self -> throw( @anything );

Throws an error which is the C<\@anything> (yes, it will be ArrayRef) to the internals of Salvation and interrupts the service.

=head3 start

 $service_instance -> start();

A method which really starts the service and returns the output of the whole process. Normally you should not want to call this method directly as your have C<Salvation::System::run_service> and C<Salvation::Service::Intent::start>.

=head2 To be redefined

You can redefine following methods to achieve your own goals.

=head3 RERUN_ON_BAD_HOOK

Should return boolean value.
Tells the system whether service should be rerun without any hooks on failure, or not.
The only argument is C<$self> which is current service's instance.
Default value is true.

=head3 cacheid

=head3 init

A method which semantics tells that it should contain custom initialziation routines, if any is needed.
The only argument is C<$self> which is current service's instance.

=head3 main

A method which semantics tells that it should contain custom code which is kind of essential for the whole service and should be executed every time. Normally it is sufficient to move such things to controller and schedule calls via C<Call>.
The only argument is C<$self> which is current service's instance.


=cut

