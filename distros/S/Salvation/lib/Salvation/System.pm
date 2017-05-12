use strict;

package Salvation::System;

use Moose;

with 'Salvation::Roles::SharedStorage', 'Salvation::Roles::AppArgs';

use Salvation::Stuff ( '&load_class', '&full_pkg' );

use Carp '&longmess';

has '__services'   => ( is => 'rw', isa => 'ArrayRef[ArrayRef[Defined]]', lazy => 1, default => sub{ [] } ); # Servicelist => Spec

has '__loaded_services'	=> ( is => 'ro', isa => 'ArrayRef[Str]', init_arg => undef, lazy => 1, builder => '__get_services' );

has '__throwable_fatals'	=> ( is => 'ro', isa => 'ArrayRef[Any]', init_arg => undef, lazy => 1, default => sub{ [] } );

sub Service
{
	my ( $self, @spec ) = @_;

	push @{ $self -> __services() }, \@spec;

	return 1;
}

sub Fatal
{
	my ( $self, @rest ) = @_;

	push @{ $self -> __throwable_fatals() }, @rest;

	return 1;
}

sub __get_services
{
	my $self     = shift;
	my @services = ();

	foreach my $spec ( @{ $self -> __services() } )
	{
		my ( $name, $flags ) = @$spec;

		if( ref( my $code = $flags -> { 'transform_name' } ) eq 'CODE' )
		{
			$name = $code -> ( $self, $name );
		}

		my $ok = 1;

		if( ref( my $code = $flags -> { 'constraint' } ) eq 'CODE' )
		{
			$ok = $code -> ( $self, $name );
		}

		if( $name and $ok )
		{
			if( &load_class( $name = $self -> __full_service_pkg( $name ) ) )
			{
				push @services, $name;
			}
		}
	}

	return \@services;
}

sub __full_service_pkg
{
	my ( $self, $name, $orig ) = @_;

	return &full_pkg( ( $orig or ref( $self ) ), 'Services', $name );
}

sub stop
{
	goto THROW_SCHEDULED_FATALS; # EVILNESS
}

sub start
{
	my $self = shift;

	$self -> main();

	my @states = ();

	foreach my $service ( @{ $self -> __loaded_services() } )
	{
		if( defined( my $state = $self -> run_service( $service ) ) )
		{
			push @states, $state;
		}
	}

THROW_SCHEDULED_FATALS:
	if( scalar( my @fatals = @{ $self -> __throwable_fatals() } ) )
	{
		if( scalar( grep{ ref } @fatals ) )
		{
			if( scalar( @fatals ) > 1 )
			{
				die \@fatals;

			} else
			{
				die @fatals;
			}
		} else
		{
			die @fatals, &longmess();
		}
	}

	return $self -> output( \@states );
}

sub run_service
{
	my ( $self, $service, @service_args ) = @_;

	my $has_hook = undef;
	my $rerun    = undef;
	my $state    = undef;

RUN_SERVICE:
	{
		eval
		{
			my $instance = $service -> new(
				@service_args,
				system   => $self,
				args     => $self -> args(),
				__nohook => ( ( $self -> args() -> { 'nohook' } or $rerun ) ? 1 : 0 )
			);

			$has_hook = ( $instance -> hook() ? 1 : 0 );
			$rerun    = $instance -> RERUN_ON_BAD_HOOK();

			if( $instance -> start() == 0 )
			{
				my $op = $instance -> output_processor();

				$state = {
					service => $service,
					state   => $instance -> state(),
					( $op ? ( op => $op ) : () )
				};

			} elsif( my $err = $instance -> storage() -> get( '$@' ) )
			{
				$self -> on_service_thrown_error( {
					'$@'     => $err,
					instance => $instance,
					service  => $service
				} );
			}
		};

		if( my $err = $@ )
		{
			eval
			{
				$self -> on_service_error( {
					'$@'	=> $err,
					service => $service
				} );
			};

			if( $has_hook and $rerun )
			{
				$self -> on_service_rerun( {
					service => $service
				} );

				redo RUN_SERVICE;
			}
		}
	}

	return $state;
}

sub main
{
}

sub output
{
	my ( undef, $states ) = @_;

	my $output = '';

	foreach my $node ( @$states )
	{
		if( my $op = $node -> { 'op' } )
		{
			$output .= eval{ $op -> main() };
		}
	}

	my ( $decl ) = ( $output =~ m/<\?xml(.+?)\?>/i );

	if( $decl )
	{
		$output =~ s/<\?xml(.+?)\?>[\n]?//gi;
		$output = sprintf( '<?xml%s?>%s<output>%s</output>', $decl, "\n", $output );
	}

	return $output;
}

sub on_service_thrown_error
{
}

sub on_service_error
{
}

sub on_service_rerun
{
}

sub on_node_rendering_error
{
}

sub on_hook_load_error
{
}

sub on_service_shared_storage_get
{
}

sub on_service_shared_storage_put
{
}

sub on_shared_storage_get
{
}

sub on_shared_storage_put
{
}

sub on_service_controller_method_error
{
}

sub on_service_shared_storage_receives_error_notification
{
}

sub on_shared_storage_receives_error_notification
{
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

# ABSTRACT: Base class for a system


=pod

=head1 NAME

Salvation::System - Base class for a system

=head1 SYNOPSIS

 package YourSystem;

 use Moose;

 extends 'Salvation::System';

 no Moose;

=head1 REQUIRES

L<Carp> 

L<Moose> 

=head1 DESCRIPTION

=head2 Applied roles

L<Salvation::Roles::SharedStorage>

L<Salvation::Roles::AppArgs>

=head1 METHODS

=head2 To be called

=head3 start

 $system_instance -> start();

A method which really starts the system and returns the output of the whole process.

=head3 stop

 $self -> stop();

A method which interrupts the system immediately.

=head3 run_service

 $self -> run_service( $absolute_package_name );
 $self -> run_service( $absolute_package_name, @service_constructor_args );

A method which runs the full cycle of the given service and returns appropriate L<Salvation::Service::State> if run was successfull.

=head3 Service

 $self -> Service( $relative_package_name );
 $self -> Service( $relative_package_name, \%flags );

Add a service with C<$name> to the list of system's services.

You can use C<\%flags> to do some tweaking providing following keys:

=over

=item transform_name

A CodeRef which will be called in order to change service's name.

 transform_name => sub
 {
 	my ( $system_instance, $service_name ) = @_;

	$service_name =~ s/MattSmith/DavidTennant/g;

	return $service_name;
 }

Useful when you feel especially crutchy.

=item constraint

A CodeRef which will be called in order to check whether the service needs to be run, or not. Should return boolean value.

 constraint => sub
 {
 	my ( $system_instance, $service_name ) = @_;

	return ( int( rand( 2 ) ) == 1 );
 }

=back

=head3 Fatal

 $self -> Fatal( @anything );

Add C<@anything> to the list of fatal errors.
The thing will C<die> with this list in the end.

=head2 To be redefined

You can redefine following methods to achieve your own goals.

=head3 main

Very first method to be executed in the execution flow.
The only argument is C<$self> which is current system's instance.

=head3 output

A method which is responsible for generating final system's output.
Its return value is the return value of C<Salvation::System::start>.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$states>

An ArrayRef of HashRefs. Each HashRef has following keys:

=over 8

=item service

Service's package name.

=item state

L<Salvation::Service::State> object instance.

=item op

L<Salvation::Service::OutputProcessor> object instance. It is not present if the service hasn't defined an output processor.

=back

=back

=head3 on_hook_load_error

Triggerred by L<Salvation::Service> when it fails to load hook.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$data>

A HashRef with error data. The keys are:

=over 8

=item C<$@>

Containts an error as it has been passed to C<die>.

=item hook

Hook's package name.

=item service

Service's package name.

=item instance

Service's instance.

=back

=back

=head3 on_node_rendering_error

Triggerred by L<Salvation::Service::View> when it fails to execute any model's method during C<process_node>.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$data>

A HashRef with error data. The keys are:

=over 8

=item C<$@>

Containts an error as it has been passed to C<die>.

=item spec

A HashRef telling how and which method has been called.

The keys are:

=over 12

=item name

Method name.

=item args

An ArrayRef with method's arguments.

=back

=item view

View's package name.

=item instance

View's instance.

=back

=back

=head3 on_service_controller_method_error

Triggerred by L<Salvation::Service> when it fails to run scheduled controller method.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$data>

A HashRef with error data. The keys are:

=over 8

=item C<$@>

Containts an error as it has been passed to C<die>.

=item method

Method name.

=item service

Service's package name.

=item instance

Service's instance.

=back

=back

=head3 on_service_error

Triggerred by L<Salvation::System> when it fails to run the service.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$data>

A HashRef with error data. The keys are:

=over 8

=item C<$@>

Containts an error as it has been passed to C<die>.

=item service

Service's package name.

=back

=back

=head3 on_service_rerun

Triggerred by L<Salvation::System> when it is about to rerun the service without hooks.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$data>

A HashRef with error data. The keys are:

=over 8

=item service

Service's package name.

=back

=back

=head3 on_service_shared_storage_get

Triggerred by L<Salvation::SharedStorage> when it is about to call its C<get> and the owner of storage is L<Salvation::Service>.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$data>

A HashRef with error data. The keys are:

=over 8

=item key

Storage key name.

=item service

Service's package name.

=item instance

Service's instance.

=back

=back

=head3 on_service_shared_storage_put

Triggerred by L<Salvation::SharedStorage> when it is about to call its C<put> and the owner of storage is L<Salvation::Service>.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$data>

A HashRef with error data. The keys are:

=over 8

=item key

Storage key name.

=item value

A value which is about to be stored.

=item service

Service's package name.

=item instance

Service's instance.

=back

=back

=head3 on_service_shared_storage_receives_error_notification

Triggerred by L<Salvation::SharedStorage> when it is about to call its C<put> with the key equal to '$@' and the owner of storage is L<Salvation::Service>.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$data>

A HashRef with error data. The keys are:

=over 8

=item data

A value which is about to be stored.

=item service

Service's package name.

=item instance

Service's instance.

=back

=back

=head3 on_service_thrown_error

Triggerred by L<Salvation::System> when the service has been interrupted and service's storage has a key named '$@'.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$data>

A HashRef with error data. The keys are:

=over 8

=item $@

Containts an error as it has been passed to C<Salvation::SharedStorage::put>.

=item service

Service's package name.

=item instance

Service's instance.

=back

=back

=head3 on_shared_storage_get

Triggerred by L<Salvation::SharedStorage> when it is about to call its C<get> and the owner of storage is L<Salvation::System>.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$data>

A HashRef with error data. The keys are:

=over 8

=item key

Storage key name.

=back

=back

=head3 on_shared_storage_put

Triggerred by L<Salvation::SharedStorage> when it is about to call its C<put> and the owner of storage is L<Salvation::System>.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$data>

A HashRef with error data. The keys are:

=over 8

=item key

Storage key name.

=item value

A value which is about to be stored.

=back

=back

=head3 on_shared_storage_receives_error_notification

Triggerred by L<Salvation::SharedStorage> when it is about to call its C<put> with the key equal to '$@' and the owner of storage is L<Salvation::System>.

Arguments

=over 4

=item C<$self>

Current system's instance.

=item C<$data>

A HashRef with error data. The keys are:

=over 8

=item data

A value which is about to be stored.

=back

=back


=cut

