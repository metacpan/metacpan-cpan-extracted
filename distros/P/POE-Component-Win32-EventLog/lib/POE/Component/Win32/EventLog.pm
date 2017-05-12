package POE::Component::Win32::EventLog;
$POE::Component::Win32::EventLog::VERSION = '1.26';
#ABSTRACT: A POE component that provides non-blocking access to Win32::EventLog.

# Author: Chris "BinGOs" Williams
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

use strict;
use warnings;

use POE 0.38 qw(Wheel::Run Filter::Line Filter::Reference);
use Win32;
use Win32::EventLog;
use Carp qw(carp croak);

our %functions = ( qw(backup Backup read Read getoldest GetOldest getnumber GetNumber clear Clear report Report) );

sub spawn {
  my $package = shift;
  croak "$package needs an even number of parameters" if @_ & 1;
  my %params = @_;

  $Win32::EventLog::GetMessageText = 1;
  $params{ lc $_ } = delete $params{$_} for keys %params;
  my $options = delete $params{'options'};

  my $self = bless \%params, $package;
  $self->{source} = 'System' unless $self->{source};

  $self->{session_id} = POE::Session->create(
	  object_states => [
	  	$self => { 'shutdown' => '_shutdown',
			   map { ( $_ => '_cmd_handler' ) } keys %functions },
	  	$self => [ qw(_start child_closed child_error child_stderr child_stdout _flush_queue _sig_chld) ],
	  ],
	  ( ( defined ( $options ) and ref ( $options ) eq 'HASH' ) ? ( options => $options ) : () ),
  )->ID();

  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub yield {
  my $self = shift;
  $poe_kernel->post( $self->session_id() => @_ );
}

sub call {
  my $self = shift;
  $poe_kernel->call( $self->session_id() => @_ );
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  $self->{session_id} = $_[SESSION]->ID();

  if ( $self->{alias} ) {
	  $kernel->alias_set( $self->{alias} );
  } else {
	  $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }

  $self->{wheel} = POE::Wheel::Run->new(
	Program     => \&_subprocess,
	ProgramArgs => [ $self->{source}, $self->{system}, $self->{dontresolveuser} ],
	CloseOnCall => 0,
    	ErrorEvent  => 'child_error',             # Event to emit on errors.
    	CloseEvent  => 'child_closed',     # Child closed all output.

    	StdoutEvent => 'child_stdout', # Event to emit with child stdout information.
    	StderrEvent => 'child_stderr', # Event to emit with child stderr information.
    	StdioFilter  => POE::Filter::Reference->new(),
	StderrFilter => POE::Filter::Line->new(),

  );

  $kernel->sig_child( $self->{wheel}->PID(), '_sig_chld' );

  $self->{shutdown} = 0;
  $self->{queuing} = 1;
  $kernel->yield( 'shutdown' ) unless $self->{wheel};
  undef;
}

sub _cmd_handler {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my $sender = $_[SENDER]->ID();
  my $func = $functions{ $_[STATE] };

  return unless $self->{wheel};

  # Get the arguments
  my $args;
  if (ref($_[ARG0]) eq 'HASH') {
	$args = { %{ $_[ARG0] } };
  } else {
	warn "first parameter must be a ref hash, trying to adjust. "
		."(fix this to get rid of this message)";
	$args = { @_[ARG0 .. $#_ ] };
  }

  foreach my $key ( keys %{ $args } ) {
	  next if ( $key =~ /^_/ );
	  $args->{ lc $key } = delete $args->{ $key };
  }
  
  unless ( $args->{event} ) {
	warn "you must supply an event argument\n";
	return;
  }

  if ( $func eq 'Backup' and scalar @ { $args->{args} } < 1 ) {
	  warn "Backup called without any arguments\n";
	  return;
  }

  if ( $func eq 'Read' and ( scalar @ { $args->{args} } < 2 or scalar @ { $args->{args} } > 2 ) ) {
	  warn "Read called without either less or more args than required.\n";
	  return;
  }

  if ( $func eq 'Report' and ref ( $args->{args}->[0] ) ne 'HASH' ) {
	  warn "Report called without the correct argument\n";
	  return;
  }

  $args->{sender} = $sender;
  $args->{func} = $func;
  unless ( $self->{shutdown} ) {
    push @{ $self->{request_queue} }, $args if $self->{queuing};
    $kernel->refcount_increment( $args->{sender} => __PACKAGE__ );
    $self->{wheel}->put( $args ) if $self->{wheel};
  }
  undef;
}

sub _sig_chld {
  $_[KERNEL]->sig_handled();
}

sub child_closed {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{wheel};
  $kernel->yield( 'shutdown' ) unless $self->{shutdown};
  undef;
}

sub child_error {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{wheel};
  $kernel->yield( 'shutdown' ) unless $self->{shutdown};
  undef;
}

sub child_stderr {
  my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];
  warn "$input\n" if $self->{debug};
  undef;
}

sub child_stdout {
  my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];

  if ( ref ( $input ) eq 'HASH' ) {
    my $session = delete $input->{sender};
    my $event = delete $input->{event};
    $kernel->post( $session, $event, $input );
    $kernel->refcount_decrement( $session => __PACKAGE__ );
  } else {
    $self->{queuing} = 0;
    $kernel->yield( '_flush_queue' );
  }
  undef;
}

sub _flush_queue {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  while ( my $args = shift @{ $self->{request_queue} } ) {
       	  $kernel->refcount_decrement( $args->{sender} => __PACKAGE__ );
  }
  undef;
}

sub shutdown {
  $_[0]->yield( 'shutdown' => @_[1..$#_] );
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  if ( $self->{alias} ) {
	  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  } else {
	  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ );
  }
  $self->{wheel}->shutdown_stdin() if $self->{wheel};
  $self->{shutdown} = 1;
  undef;
}

sub _subprocess {
  binmode(STDIN); binmode(STDOUT);
  my ($source,$system,$dontresolveuser) = splice @_, 0, 3;
  my $raw;
  my $size = 4096;
  my $filter = POE::Filter::Reference->new();

  my $handle = Win32::EventLog->new( $source, $system );

  unless ( $handle->{handle} ) { # dirty hack
	 print STDERR "Couldn\'t create an eventlog handle for $source $system\n";
         my $ready = $filter->put( [ [] ] );
         print STDOUT @$ready;
	 return;
  }

  while ( sysread ( STDIN, $raw, $size ) ) {
    my $requests = $filter->get( [ $raw ] );
    foreach my $req ( @{ $requests } ) {
      SWITCH: {
	my $func = $req->{func};
	if ( $req->{func} =~ /^(GetOldest|GetNumber)$/ ) {
		my $scalar;
		if ( $handle->$func($scalar) ) {
		   $req->{result} = $scalar;
		} else {
		   $req->{error} = &_error_codes;
		}
		last SWITCH;
	}
	if ( $req->{func} =~ /^(Backup|Clear)$/ ) {
		if ( my $result = $handle->$func( @{ $req->{args} } ) ) {
			$req->{result} = $result;
		} else {
		   $req->{error} = &_error_codes;
		}
		last SWITCH;
	}
	if ( $req->{func} eq 'Read' ) {
		my $hashref = {};
		if ( my $result = $handle->$func( @{ $req->{args} }, $hashref ) ) {
			$req->{result} = $hashref;
			unless ( $dontresolveuser ) {
			  $req->{result}->{User} = _lookupaccountsid( $req->{result}->{User} );
			}
		} else {
		   $req->{error} = &_error_codes;
		}
		last SWITCH;
	}
	if ( $req->{func} eq 'Report' ) {
		if ( my $result = $handle->$func( @{ $req->{args} } ) ) {
			$req->{result} = $result;
		} else {
		   $req->{error} = &_error_codes;
		}
		last SWITCH;
	}
      }
      my $replies = $filter->put( [ $req ] );
      print STDOUT @$replies;
    }
  }
}

sub _error_codes {
  my $error = Win32::GetLastError();
  return [ $error, Win32::FormatMessage($error) ];
}

sub _lookupaccountsid {
  my $sid = shift || return '';

  return $sid unless $sid;
  my ($account,$domain,$sidtype);
  eval {
    Win32::LookupAccountSID("",$sid,$account,$domain,$sidtype);
  };
  return "$domain\\$account";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Win32::EventLog - A POE component that provides non-blocking access to Win32::EventLog.

=head1 VERSION

version 1.26

=head1 SYNOPSIS

  use POE qw(Component::Win32::EventLog);
  use Win32::EventLog;
  use Data::Dumper;

  my $eventlog = POE::Component::Win32::EventLog->spawn();

  POE::Session->create(
    package_states => [
  	'main' => [ qw(_start _getoldest _getnumber _event_logs) ],
    ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
	$eventlog->yield( getoldest => { event => '_getoldest' } );
	undef;
  }

  sub _getoldest {
	my $heap = $_[HEAP];
	my ($hashref) = $_[ARG0];
	unless ( $hashref->{result} ) {
		$eventlog->yield( 'shutdown' );
		return;
	}
	$heap->{oldest} = $hashref->{result};
	$eventlog->yield( getnumber => { event => '_getnumber' } );
	undef;
  }

  sub _getnumber {
	my $heap = $_[HEAP];
	my ($hashref) = $_[ARG0];
	unless ( $hashref->{result} ) {
		$eventlog->yield( 'shutdown' );
		return;
	}
	my $x = 0; my $last = 0;
	while ( $x < $hashref->{result} ) {
		$eventlog->yield( read => { event => '_event_logs', 
		  args => [ EVENTLOG_FORWARDS_READ|EVENTLOG_SEEK_READ, $heap->{oldest} + $x ], _last => $last } );
		$x++;
		if ( $x == ( $hashref->{result} - 1 ) ) { $last = 1; }
	}
	undef;
  }

  sub _event_logs {
	my $heap = $_[HEAP];
	my ($hashref) = $_[ARG0];

	if ( $hashref->{result} ) {
		print STDOUT Dumper( $hashref->{result} );
	}
	if ( $hashref->{_last} ) {
		$eventlog->yield( 'shutdown' );
	}
	undef;
  }

=head1 DESCRIPTION

POE::Component::Win32::EventLog is a L<POE> component that provides a non-blocking wrapper around
L<Win32::EventLog>. Each component instance represents a Win32::EventLog object.

Consult the L<Win32::EventLog> documentation for more details.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Takes a number of arguments, all of which are optional. 

  'source', SOURCENAME argument for Win32::EventLog, default is 'System' if none is supplied;
  'system', the SERVERNAME argument for Win32::EventLog;
  'alias', the kernel alias to bless the component with;
  'debug', set this to 1 to see component debug information; 
  'options', a hashref of POE::Session options that are passed to the component's session creator.
  'dontresolveuser', set to 1 to stop the component automagically resolving the User field from a SID 
  	to a 'proper' username. 

=back

=head1 METHODS

=over

=item C<session_id>

Takes no arguments. Returns the ID of the component's session. Ideal for posting
events to the component.

=item C<yield>

This method provides an alternative object based means of posting events to the component.
First argument is the event to post, following arguments are sent as arguments to the resultant
post.

=item C<call>

This method provides an alternative object based means of calling events to the component.
First argument is the event to call, following arguments are sent as arguments to the resultant
call.

=item C<shutdown>

Terminates the component instance.

=back

=head1 INPUT

These are the events that the component will accept. All require a hashref as the first parameter. All require that
the hashref contain the 'event' key which contains the name of the event handler in *your* session that you want the result of the requested operation to go to. If a function requires additional arguments the 'args' key can be used which must be an arrayref of values. Check with L<Win32::EventLog> for details.

You may pass arbitary key/values in the hashref, please ensure that the keys begin with an underscore. See SYNOPSIS for an example.

=over

=item C<backup>

Backs up the eventlog. You must specify a filename in 'args' arrayref.

=item C<clear>

Clears the eventlog.

=item C<getnumber>

Returns the number of EventLog records in the EventLog.

=item C<getoldest>

Returns the number of the oldest EventLog record in the EventLog.

=item C<read>

Returns the indicated eventlog record from the eventlog. 

=item C<report>

Generates an EventLog entry. You must specify a hashref representing the record to be added, using 'args'.

=item C<shutdown>

Terminates the component instance.

=back

=head1 OUTPUT

For each requested operation an event handler is required. ARG0 of this event handler contains a hashref.

=over

=item C<result>

For most cases this will be just a true value. For 'getnumber' and 'getoldest' it will be an integer.
For 'read', it will be a hashref representing the eventlog record ( see L<Win32::EventLog> for
details ( the component automagically resolves the User field from a SID to a 'proper' username ).

=item C<error>

In the event of an error occurring this will be defined. It is an arrayref which contains the error code and the formatted error relating to that code.

=back

=head1 CAVEATS

This module will only work on Win32. But you guessed that already :)

=head1 SEE ALSO

L<POE>

L<Win32::EventLog>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
