package POE::Component::Client::Telnet;

use POE 0.31;
use POE::Wheel::Run;
use POE::Filter::Line;
use POE::Filter::Reference;
use Net::Telnet;
use Carp qw(carp croak);
use Devel::Symdump;
use vars qw($AUTOLOAD);

use strict;

our $VERSION = '0.06';

sub AUTOLOAD {
	my $self = shift;
	my $method = $AUTOLOAD;
	$method =~ s/.*:://;
	return unless $method =~ /[^A-Z]/;
	
	warn "autoload method $method" if ($self->{debug});
	
	my $hash = shift;
	croak 'first param must be a hash ref of options' unless (ref($hash) eq 'HASH');
	
	$hash->{wantarray} = wantarray() unless (defined($hash->{wantarray}));
	$poe_kernel->post($self->session_id() => $method => $hash => @_);
}

sub spawn {
	goto &new;
}

sub new {
	my $package = shift;
	croak "$package needs an even number of parameters" if @_ & 1;
	my %params = @_;

	foreach my $param ( keys %params ) {
		$params{ lc $param } = delete ( $params{ $param } );
	}

	my $options = delete ( $params{'options'} );
	$params{package} ||= 'Net::Telnet';

	# map of commands to packages
	$params{cmd_map} = {};

	my $self = bless(\%params, $package);

	if ($params{package} ne 'Net::Telnet') {
		eval "use $params{package}";
		die $@ if ($@);
	}
	
	my @obj = Devel::Symdump->functions('Net::Telnet');
	push(@obj,Devel::Symdump->functions($params{package}));
	
	foreach my $p (@obj) {
		my ($pk,$sub) = ($p =~ m/^(.+)\:\:([^\:]+)/);
	
		next unless ($sub =~ /[^A-Z_0-9]$/);
		next if ($sub =~ m/^_/ || $sub =~ m/(carp|croak|confess)$/);
		my $o = $p;
		
		if (defined &$o) {
			$self->{cmd_map}->{$sub} = $pk;
		}
	}
	
	$self->{session_id} = POE::Session->create(
		object_states => [
			$self => { (map { $_ => 'request' } keys %{$self->{cmd_map}}) },
			$self => [ qw(_start shutdown wheel_close wheel_err wheel_out wheel_stderr) ],
		],
		( ( defined ( $options ) and ref ( $options ) eq 'HASH' ) ? ( options => $options ) : () ),
	)->ID();

	warn "session $self->{session_id} created for $params{package}" if ($self->{debug});
	
	return $self;
}

# POE related object methods

sub _start {
	my ($kernel,$self) = @_[KERNEL,OBJECT];

	if ( $self->{alias} ) {
		$kernel->alias_set( $self->{alias} );
	} else {
		$kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
	}

	$self->{wheel} = POE::Wheel::Run->new(
		Program      => \&process_requests,
		CloseOnCall  => 0,
		StdinFilter  => POE::Filter::Reference->new(),
		StdoutFilter => POE::Filter::Reference->new(),
		StderrFilter => POE::Filter::Line->new(),
		StdoutEvent  => 'wheel_out',
		StderrEvent  => 'wheel_stderr',
		ErrorEvent   => 'wheel_err',
		CloseEvent   => 'wheel_close',
	);

	# adjust options 
	if ($self->{package} ne 'Net::Telnet') {
		$self->{telnet_options} = [ (@{$self->{telnet_options}}, '_Package' => $self->{package}) ];
	}

	if ($self->{telnet_options} && ref($self->{telnet_options}) eq 'ARRAY') {
		$self->{wheel}->put($self->{telnet_options});
	}

	undef;
}

sub request {
	my ($kernel,$self,$state,$sender) = (@_[KERNEL,OBJECT,STATE],$_[SENDER]->ID);
  
	warn "processing request $state\n" if ($self->{debug});
	# Get the arguments
	my $args;
	if (ref($_[ARG0]) eq 'HASH') {
		$args = { %{ $_[ARG0] } };
	} else {
		warn "first parameter must be a ref hash, trying to adjust. "
			."(fix this to get rid of this message)";
		$args = { @_[ARG0 .. $#_ ] };
	} 
 
	if ($self->{wheel}) {
		$args->{session} = $sender;
		$args->{func} = $state;
		$args->{state} = $state;
		$args->{args} = [ @_[ ARG1 .. $#_ ] ];
	
		# if we have an event to report to...make sure we stay around
		if ($args->{event}) {
			$kernel->refcount_increment($sender => __PACKAGE__);
		}
		
		$self->{wheel}->put($args);
	}
	
	undef;
}

sub wheel_out {
	my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];

	delete $input->{func};
  
	my $session = delete $input->{session};
	my $event = delete $input->{event};

	if ($event) {
		$kernel->post($session => $event => $input);
		$kernel->refcount_decrement($session => __PACKAGE__);
	}
  
	undef;
}

sub wheel_stderr {
	my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];

	warn "$input\n" if ($self->{debug});
}

sub wheel_err {
    my ($self, $operation, $errnum, $errstr, $wheel_id) = @_[OBJECT, ARG0..ARG3];
	
    warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n" if ($self->{debug});
}

sub wheel_close {
	my $self = $_[OBJECT];
	
	warn "Wheel closed\n" if ($self->{debug});
	
	warn "$self->{package} Wheel closed, ieeeeeeee!\n";
}

# Dual event and object methods

sub shutdown {
	unless (UNIVERSAL::isa($_[KERNEL],'POE::Kernel')) {
		if ($poe_kernel) {
			$poe_kernel->call(shift->session_id() => 'shutdown' => @_);
		}
		return;
	}
	
	my ($kernel,$self) = @_[KERNEL,OBJECT];

	# remove alias or decrease ref count
	if ($self->{alias}) {
		$kernel->alias_remove($_) for $kernel->alias_list();
	} else {
		$kernel->refcount_decrement($self->session_id() => __PACKAGE__);
	}
	
	if ($self->{wheel}) {
		$self->{wheel}->shutdown_stdin;
	}
	undef;
}


# Object methods

sub session_id {
	shift->{session_id};
}

sub yield {
	my $self = shift;
	$poe_kernel->post($self->session_id() => @_);
}

sub call {
	my $self = shift;
	$poe_kernel->call($self->session_id() => @_);
}

sub DESTROY {
	if (UNIVERSAL::isa($_[0],__PACKAGE__)) {
		$_[0]->shutdown();
	}
}

# Main Wheel::Run process sub

sub process_requests {
	binmode(STDIN);
	binmode(STDOUT);

	my $raw;
	my $size = 4096;
	my $filter = POE::Filter::Reference->new();

	# telnet object
	my $t;

	# there's room for other callbacks
	my %callbacks = (
		option_callback => undef,
	);
	
	READ:
	while ( sysread ( STDIN, $raw, $size ) ) {
		my $requests = $filter->get([$raw]);

		unless ($t) {
			my $arg = shift(@{$requests});
			if (ref($arg) eq 'ARRAY') {
				my $package = 'Net::Telnet';
				my %args = ( @$arg );
				if ($args{_Package}) {
					$package = delete $args{'_Package'};
					eval "use $package";
					if ($@) {
						die "$@\n";
					}
				}
				$t = $package->new(%args);
			} else {
				$t = Net::Telnet->new();
				unshift(@{$requests},$arg);
			}
		}
		
    	foreach my $req (@{$requests}) {
			my $func = $req->{func};
			
			if ($func eq 'option_callback') {
				if (@{$req->{args}}) {
					# set the callback event
					$callbacks{$func} = $req->{args}->[0];
					# TODO allow unsetting event?   Net::Telnet doesn't allow it...
					# then set a coderef to post that back
					$t->$func(sub {
						# $obj, $option, $is_remote, $is_enabled, $was_enabled, $buf_position
						shift; # don't need and can't send the object
						$req->{result} = [ @_ ];
						$req->{event} = $callbacks{$func};
						my $rep = $filter->put( [ $req ] );
						print STDOUT @$rep;
					});
				} else {
					$req->{result} = $callbacks{$func};
					my $rep = $filter->put( [ $req ] );
					print STDOUT @$rep;
				}
				next;
			}

			my @result;
			eval {
				@result = $t->$func(@{$req->{args}});
			};
			if ($@) {
				$req->{error} = $@;
				@result = undef;
			}
			
			if ($req->{wantarray}) {
				$req->{result} = \@result;
			} else {
				$req->{result} = $result[0];
			}
			
			my $replies = $filter->put( [ $req ] );
			print STDOUT @$replies;
		}
	}
}

1;

__END__

=head1 NAME

POE::Component::Client::Telnet - A POE component that provides non-blocking access to Net::Telnet
and other subclasses of Net::Telnet.

=head1 SYNOPSIS

	use POE::Component::Client::Telnet;

	my $poco = POE::Component::Client::Telnet->new(
	  	alias => 'telnet',                # optional; You can use $poco->session_id() instead
		debug => 1,                       # optional; 1 to turn on debugging
		options => { trace => 1 },        # optional; Options passed to the internal session
		package => 'Net::Telnet::Cisco',  # optional; Allows use of other Net::Telnet
		telnet_options => [ ],            # optional; Options passed to Net::Telnet->new()
	);

	# Start your POE session, then...

	$kernel->post('telnet' => open => { event => 'result' },"rainmaker.wunderground.com");

	sub result {
		my ($kernel,$ref) = @_[KERNEL,ARG0];

		if ( $ref->{result} ) {
			print "connected: $ref->{result}\n";
		} else {
			print STDERR join(' ', @{ $ref->{error} ) . "\n";
		}
	}

=head1 DESCRIPTION

POE::Component::Client::Telnet is a L<POE> component that provides a non-blocking wrapper around
L<Net::Telnet>, or any other module based on L<Net::Telnet>.

Consult the L<Net::Telnet> documentation for more details.

=head1 METHODS

=over

=item new

Takes a number of arguments, all of which are optional. 'alias', the kernel alias to bless the component with;
'debug', set this to 1 to see component debug information; 'options', a hashref of L<POE::Session> 
options that are passed to the component's session creator; 'telnet_options', an optional array ref of options
that will be passed to Net::Telnet->new(); 'package', an optional package name that is a base of L<Net::Telnet>,
like L<Net::Telnet::Cisco>.

=item session_id

Takes no arguments, returns the L<POE::Session> ID of the component. Useful if you don't want to use aliases.

=item yield

This method provides an alternative object based means of posting events to the component. First argument is 
the event to post, following arguments are sent as arguments to the resultant post.

  $poco->yield( open => { event => 'result' }, "localhost" );

=item call

This method provides an alternative object based means of calling events to the component. First argument is
the event to call, following arguments are sent as arguments to the resultant call.

  $poco->call( open => { event => 'result' }, "localhost" );

=item (all other L<Net::Telnet> methods

All L<Net::Telnet> methods can be called, but the first param must be the options hash as noted below in
the INPUT section below.

For example:
	
	$poco->open( { event => 'opened' },"localhost" );

One exception, the 'option_callback' method accepts an event name instead of a code ref.  If called with no
params, 'result' will be the event currently set.  Also, when the callback is fired, 'result' will be an array
ref of $option, $is_remote, $is_enabled, $was_enabled, $buf_position.  See the 'option_callback' method of
L<Net::Telnet> for details.

=back

=head1 INPUT

These are the events that the component will accept. Each event requires a hashref
as an argument with the following keys: 'event', the name of the event handler in
*your* session that you want the result of the requested operation to go to. 'event'
is needed for all requests that you want a response to.

It is possible to pass arbitary data in the request hashref that could be used
in the resultant event handler. Simply define additional key/value pairs of your
own. It is recommended that one prefixes keys with '_' to avoid future clashes.

=head1 OUTPUT

For each requested operation an event handler is required. ARG0 of this event
handler contains a hashref.

The hashref will contain keys for 'state', and 'result'. 'state' is the operation
that was requested, 'result' is what the
function returned.

=over

=item result

This is data returned from the function you called.  Usually a scalar, but can be
an array ref when using 'option_callback'.

=item error

In the event of an error occurring this will be defined. It is an scalar which
contains the error.

=back

=head1 AUTHOR

David Davis E<lt>xantus@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<Net::Telnet>, L<Net::Telnet::Cisco>, L<Net::Telnet::Netscreen>, L<Net::Telnet::Options>

=head1 RATING

Please rate this module. L<http://cpanratings.perl.org/rate/?distribution=POE-Component-Client-Telnet>

=head1 BUGS

Probably.  Report them here: L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE%3A%3AComponent%3A%3AClient%3A%3ATelnet>

=head1 CREDITS

BinGOs for L<POE::Component::Win32::Service> that helped me get started.

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by David Davis and Teknikill Software

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

