package POE::Component::Audio::Mad::Handle;
require 5.6.0;

$| = 1;

use warnings;
use strict;

use Carp qw(carp);
use POE qw(Wheel::ReadWrite Driver::SysRW Filter::Audio::Mad::Stdio);
use POE::Wheel::Audio::Mad;

our $VERSION = '0.2';

## this is a simpler solution,  as it merely relies on parsing commands
## fed to it on STDIN and it returns output on STDOUT.  There are problems
## with this design,  however,  we need to find a way to allow spaces
## in command arguments,  or at least do simple quoting.  I have a feeling
## I'm about to get pretty intimate with non-backtracking regexes or
## something..

sub create {
	my ($class, $args) = @_;

	## we process some of our arguments and set some
	## defaults rather early,  we use this hash to 
	## hold the arguments for the wheel to be created..

	$args->{filter} = new POE::Filter::Audio::Mad::Stdio unless (defined($args->{filter}));
	$args->{driver} = new POE::Driver::SysRW unless (defined($args->{driver}));
	
	my %wheel = (
		Driver      => $args->{driver},
		Filter      => $args->{filter},
		
		InputEvent  => 'input',
		ErrorEvent  => 'error',
	);
	
	## check to see what the user wants,  if unspecified
	## STDIN will be used for input and STDOUT will
	## be used for output.  we do this here so we can
	## fail a bit more gracefully..  better to fail
	## creation than to die in _start.
	
	if (defined($args->{handle})) {
		$wheel{Handle} = $args->{handle};
	} else {
		$wheel{InputHandle}  = $args->{input_handle}  if (defined($args->{input_handle} ));
		$wheel{OutputHandle} = $args->{output_handle} if (defined($args->{output_handle}));
		
		unless (defined($wheel{InputHandle})) {
			open (my $stdin, '-') || do {
				carp "failed to open STDIN for reading,  aborting!";
				return undef;
			};
			
			$wheel{InputHandle} = $stdin;
		}
		
		unless (defined($wheel{OutputHandle})) {
			open (my $stdout, '>-') || do {
				carp "failed to open STDOUT for writing,  aborting!";
				return undef;
			};
			
			$wheel{OutputHandle} = $stdout;
		}
	}

	## create our own session,  and return it back
	## to the caller.
	POE::Session->create(
		inline_states => {
			_start            => \&_start,
			_stop             => \&_stop,
			_shutdown_flushed => \&_shutdown_flushed,
			
			shutdown  => \&shutdown,
			put       => \&put,
			input     => \&input,
			error     => \&error
		},
		args => [\%wheel]
	);
}


sub _start {
	my ($heap, $kernel, $args) = @_[HEAP, KERNEL, ARG0];

	## fix: we need to do something about this..
	$kernel->alias_set('mad-decoder');

	## just use the arguments that were generated for us,
	## above.
	$heap->{wheel}   = POE::Wheel::ReadWrite->new( %{$args} );
	$heap->{decoder} = POE::Wheel::Audio::Mad->new( message_event => 'put' );
}

sub _stop { undef }

##############################################################################

sub shutdown {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	$heap->{wheel}->event( FlushedEvent => '_shutdown_flushed' );
	$kernel->yield('put', {
		id   => 'IPC_SHUTDOWN_SUCCESS',
		data => ''
	});
}

sub _shutdown_flushed {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	undef $heap->{wheel};
	$kernel->alias_remove('mad-decoder');
}
	
sub put {
	my ($heap, $msg) = @_[HEAP, ARG0];
	$heap->{wheel}->put($msg) if (defined($heap->{wheel}));
}

sub input {
	my ($kernel, $raw) = @_[KERNEL, ARG0];
	
	return undef unless (defined($raw->{id}) && $raw->{id} ne '');
	$kernel->yield("decoder_$raw->{id}", $raw->{data});
}

sub error {
	my ($kernel, $efunc, $error) = @_[KERNEL, ARG0, ARG2];
	
	$kernel->yield('put', {
		id   => 'IPC_INPUT_ERROR',
		data => "failure during '$efunc': $error",
	});
	
	$kernel->post('mad-decoder', 'shutdown');
}

##############################################################################
1;
__END__
=pod

=head1 NAME

POE::Component::Audio::Mad::Handle - A POE Component to facilitate IPC with
the POE::Wheel::Audio::Mad mpeg decoder.

=head1 SYNOPSIS

	use POE;
	use POE::Component::Audio::Mad::Handle;

	## create an IPC bridge on stdin/stdout
	create POE::Component::Audio::Mad::Handle();
	
	## create a custom IPC bridge..
	create POE::Component::Audio::Mad::Handle (
		Driver  => POE::Driver::SysRW->new(),
		Filter  => POE::Filter::Audio::Mad->new(),
		
		Handle  => $two_way_handle,
		# -or-
		InputHandle  => $one_way_handle_in,
		OutputHandle => $one_way_handle_out
	);
	
=head1 DESCRIPTION

  POE::Component::Audio::Mad::Handle is a POE Component to implement 
  basic inter-process communication with the POE::Wheel::Audio::Mad 
  mpeg decoder and a bi-directional or two unidirectional filehandles.
  
  This Component operates by creating an instance of POE::Wheel::Audio::Mad
  and an instance of POE::Wheel::ReadWrite and then facilitates communication
  between the two.  All options passed to the create() constructor are
  filled in with defaults and then directly passed to POE::Wheel::ReadWrite's
  constructor;  see it's documentation for a description of available options.
  
  You may use any options you wish.  Decoder status messages will be sent
  through the filter and then delivered to the appropriate filehandle.  
  Commands received through the appropriate filehandle will be sent
  through the filter and used to affect POE::Wheel::Audio::Mad operations.
  
=head1 DEFAULTS

  If some of the options to the create() constructor aren't present,  this
  component will fill them in with it's own defualts.
  
=over

=item InputHandle and OutputHandle

  If a Handle is not specified or an InputHandle and an OutputHandle aren't 
  specified,  this module will use STDIN as the default InputHandle and STDOUT 
  as the default OutputHandle.
  
=item Driver

  If unspecified we will use POE::Driver::SysRW.
  
=item Filter

  If unspecified we will use POE::Filter::Audio::Mad which comes with
  this distribution.

=back

=head1 SEE ALSO

perl(1)

POE::Wheel::ReadWrite(3)

POE::Filter::Audio::Mad(3)
POE::Wheel::Audio::Mad(3)

=head1 AUTHOR

Mark McConnell, E<lt>mischke@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mark McConnell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself with the exception that you
must also feel bad if you don't email me with your opinions of
this module.

=cut
