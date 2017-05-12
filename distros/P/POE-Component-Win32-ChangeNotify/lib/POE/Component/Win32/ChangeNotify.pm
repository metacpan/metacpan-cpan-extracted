# Author: Chris "BinGOs" Williams
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

package POE::Component::Win32::ChangeNotify;
$POE::Component::Win32::ChangeNotify::VERSION = '1.24';
#ABSTRACT: A POE wrapper around Win32::ChangeNotify.

use strict;
use warnings;
use POE 0.38 qw(Wheel::Run Filter::Reference Filter::Line);
use Win32;
use Win32::ChangeNotify;
use Carp qw(carp croak);

sub spawn {
  my $package = shift;
  croak "$package needs an even number of parameters" if @_ & 1;
  my %params = @_;

  $params{ lc $_ } = delete $params{ $_ } for keys %params;
  my $options = delete $params{'options'};

  my $self = bless \%params, $package;

  $self->{session_id} = POE::Session->create(
	  object_states => [
		  $self => [ qw(_start _sig_chld child_closed child_error child_stderr child_stdout shutdown monitor unmonitor) ],
	  ],
	  ( ( defined ( $options ) and ref ( $options ) eq 'HASH' ) ? ( options => $options ) : () ),
  )->ID();

  $self->{FILTERS} = [ qw(ATTRIBUTES DIR_NAME FILE_NAME LAST_WRITE SECURITY SIZE) ];

  return $self;
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  $self->{session_id} = $_[SESSION]->ID();

  if ( $self->{alias} ) {
	$kernel->alias_set( $self->{alias} );
  } else {
	$kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }

  #$kernel->sig( 'CHLD' => '_sig_chld' );
  $self->{wheels} = { };
  undef;
}

sub _sig_chld {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->sig_handled();
}

sub shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  if ( $self->{alias} ) {
	$kernel->alias_remove( $_ ) for $kernel->alias_list();
  } else {
	$kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ );
  }

  # Clean up wheels before we go.
  $self->{_wheel_count} = scalar keys %{ $self->{wheels} };
  foreach my $wheel_id ( keys %{ $self->{wheels} } ) {
	  $self->{wheels}->{ $wheel_id }->{wheel}->kill(9);
	  my $wheel_data = delete $self->{wheels}->{ $wheel_id };
	  $kernel->refcount_decrement( $wheel_data->{sender} => __PACKAGE__ );
  }
  delete $self->{monitored};
  #$kernel->sig( 'CHLD' ) unless $self->{_wheel_count};
  $self->{_shutdown} = 1;
  undef;
}

sub monitor {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my $sender = $_[SENDER]->ID();

  # Get the arguments
  my $args;
  if (ref($_[ARG0]) eq 'HASH') {
	$args = { %{ $_[ARG0] } };
  } else {
	warn "first parameter must be a ref hash, trying to adjust. "
		."(fix this to get rid of this message)";
	$args = { @_[ARG0 .. $#_ ] };
  }

  $args->{ lc $_ } = delete $args->{$_} for keys %{ $args };
  
  unless ( $args->{path} ) {
	warn "you must supply a path argument, otherwise what's the point";
	return;
  }

  unless ( $args->{event} ) {
	warn "you must supply an event argument, otherwise where do I send the replies to";
	return;
  }

  unless ( $args->{filter} ) {
	  $args->{filter} = join(' ', @{ $self->{FILTERS} } );
  }

  $args->{sender} = $sender;
  
  unless ( defined ( $self->{monitored}->{ $args->{path} } ) ) {
    $args->{always} = 1;
    my $wheel = POE::Wheel::Run->new(
    	Program     => \&_launch_change_notify,
    	ErrorEvent  => 'child_error',             # Event to emit on errors.
    	CloseEvent  => 'child_closed',     # Child closed all output.

    	StdoutEvent => 'child_stdout', # Event to emit with child stdout information.
    	StderrEvent => 'child_stderr', # Event to emit with child stderr information.
    	StdioFilter  => POE::Filter::Reference->new(),
	StderrFilter => POE::Filter::Line->new(),   
    	CloseOnCall => 0,
    );

    if ( $wheel ) {
    	$kernel->refcount_increment( $sender => __PACKAGE__ );
    	$wheel->put( $args );
    	$self->{wheels}->{ $wheel->ID() }->{wheel} = $wheel;
    	$self->{wheels}->{ $wheel->ID() }->{args} = $args;
    	$self->{wheels}->{ $wheel->ID() }->{sender} = $sender;
	$self->{monitored}->{ $args->{path} } = $wheel->ID();
        $kernel->sig_child( $wheel->PID, '_sig_chld' );
    }
  }

  undef;
}

sub unmonitor {
  my ($kernel,$self,$state) = @_[KERNEL,OBJECT,STATE];
  croak "$state event needs an even number of parameters" if @_ & 1;
  my %params = @_;

  $params{ lc $_ } = delete ( $params{ $_ } ) for keys %params;

  my $path = delete $params{path};

  croak "$state requires a path parameter" unless $path;

  if ( defined ( $self->{monitored}->{ $path } ) ) {
	my $wheel_id = delete $self->{monitored}->{ $path };
	$self->{wheels}->{ $wheel_id }->{wheel}->kill();
	my $wheel_data = delete $self->{wheels}->{ $wheel_id };
	$kernel->refcount_decrement( $wheel_data->{sender} => __PACKAGE__ );
  }

  undef;
}

sub child_closed {
  my ($self,$wheel_id) = @_[OBJECT,ARG0];

  my $wheel_data = delete $self->{wheels}->{ $wheel_id };
  delete $self->{monitored}->{ $wheel_data->{args}->{path} };
  undef;
}

sub child_error {
  my ($self,$wheel_id) = @_[OBJECT,ARG3];

  my $wheel_data = delete $self->{wheels}->{ $wheel_id };
  delete $self->{monitored}->{ $wheel_data->{args}->{path} };
  undef;
}

sub child_stdout {
  my ($kernel,$self,$input,$wheel_id) = @_[KERNEL,OBJECT,ARG0,ARG1];
  delete $input->{always};
  my $event = delete $input->{event};
  my $sender = delete $input->{sender};

  $kernel->post( $sender => $event => $input );
  undef;
}

sub child_stderr {
  my ($kernel,$self,$input,$wheel_id) = @_[KERNEL,OBJECT,ARG0,ARG1];

  undef;
}

sub session_id {
  return $_[0]->{session_id};
}

sub _launch_change_notify {
  binmode(STDIN); binmode(STDOUT); 
  my $raw;
  my $size = 4096;
  my $filter = POE::Filter::Reference->new();

  READ:
  while ( sysread ( STDIN, $raw, $size ) ) {
    my $requests = $filter->get( [ $raw ] );
    _watch_path($filter,$_) for @{ $requests };
  }
}

sub _watch_path {
  my ($filter,$req) = splice @_, 0, 2;

  my $notify = Win32::ChangeNotify->new($req->{path}, $req->{subtree}, $req->{filter});

  unless ( $notify ) {
	delete $req->{result};
	$req->{error} = "Couldn't create Win32::ChangeNotify object: " .
				Win32::FormatMessage( Win32::GetLastError() );
	my $replies = $filter->put( [ $req ] );
	print STDOUT @$replies;
	return 0;
  }

  while ( $req->{always} ) {
	$notify->reset;
	my $result = $notify->wait;

	if ( $result ) {
	  $req->{result} = $result;
	  my $replies = $filter->put( [ $req ] );
	  print STDOUT @$replies;
	} else {
	  delete $req->{result};
	  $req->{error} = "Something bad happened with the Win32::ChangeNotify object";
	  my $replies = $filter->put( [ $req ] );
	  print STDOUT @$replies;
	}
  }
  $notify->close;
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Win32::ChangeNotify - A POE wrapper around Win32::ChangeNotify.

=head1 VERSION

version 1.24

=head1 SYNOPSIS

   use strict;
   use POE;
   use POE::Component::Win32::ChangeNotify;

   my $poco = POE::Component::Win32::ChangeNotify->spawn( alias => 'blah' );

   POE::Session->create(
   	package_states => [ 
		'main' => [ qw(_start notification) ],
	],
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
     my ($kernel,$heap) = @_[KERNEL,HEAP];

     $kernel->post( 'blah' => monitor => 
     {
     	'path' => '.',
	'event' => 'notification',
	'filter' => 'ATTRIBUTES DIR_NAME FILE_NAME LAST_WRITE SECURITY SIZE',
	'subtree' => 1,
     } );

     undef;
   }

   sub notification {
     my ($kernel,$hashref) = @_[KERNEL,ARG0];

     if ( $hashref->{error} ) {
     	print STDERR $hashref->{error} . "\n";
     } else {
     	print STDOUT "Something changed in " . $hashref->{path} . "\n";
     }
     $kernel->post( 'blah' => 'shutdown' );
     undef;
   }

=head1 DESCRIPTION

POE::Component::Win32::ChangeNotify is a POE wrapper around L<Win32::ChangeNotify> that provides non-blocking change notify events to your POE sessions.

=head1 METHODS

=over

=item C<spawn>

Takes a number of arguments, all of which are optional.

  'alias', the kernel alias to bless the component with; 
  'options', a hashref of POE::Session options that are passed to the component's 
             session creator.

=item C<session_id>

Takes no arguments, returns the L<POE::Session> ID of the component. Useful if you don't want to use
aliases.

=back

=head1 INPUT

These are the events that the component will accept.

=over

=item C<monitor>

Starts monitoring the specified path for the specified types of changes.

Accepts one argument, a hashref containing the following keys: 

  'path', the filesystem path to monitor, mandatory; 
  'event', the event handler to post results back to, mandatory.
  'filter', a string containing whitespace or '|' separated notification flags, 
            see Win32::ChangeNotify for details, defaults to all notification flags; 
  'subtree', set this to true value to monitor all subdirectories under 'path'; 

     $kernel->post( 'blah' => monitor => 
     {
     	'path' => '.',
	'event' => 'notification',
	'filter' => 'ATTRIBUTES DIR_NAME FILE_NAME LAST_WRITE SECURITY SIZE',
	'subtree' => 1,
     } );

=item C<unmonitor>

Stops monitoring the specified path.

Accepts one mandatory argument, 'path', the filesystem path to stop monitoring.

   $kernel->post( 'blah' => unmonitor => path => '.' );

=item C<shutdown>

Has no arguments. Shuts down the component gracefully. All monitored paths will be closed.

=back

=head1 OUTPUT

Each event sent by the component has a hashref as ARG0. This is the hashref that was passed to the component with monitor(). The key 'result' will be true if a change has occurred. The key 'error' will be set if an error occurred during the setup of the Win32::ChangeNotify object or when trying to call 'wait' on the object. 

=head1 CAVEATS

This module will only work on Win32. But you guessed that already :)

=head1 SEE ALSO

L<Win32::ChangeNotify>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
