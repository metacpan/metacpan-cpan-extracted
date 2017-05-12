package POE::Component::AI::MegaHAL;
$POE::Component::AI::MegaHAL::VERSION = '1.20';
#ABSTRACT: A non-blocking wrapper around AI::MegaHAL.

use strict;
use warnings;
use AI::MegaHAL;
use POE qw(Wheel::Run Filter::Line Filter::Reference);
use Carp;

sub spawn {
  my $package = shift;
  my %params = @_;

  $params{ lc $_ } = delete $params{$_} for keys %params;
  $params{'autosave'} = 1 unless defined ( $params{'autosave'} ) and $params{'autosave'} eq '0';
  my $options = delete $params{'options'};
  my $self = bless \%params, $package;

  POE::Session->create(
	object_states => [
		$self => {
			do_reply         => '_megahal_function',
			initial_greeting => '_megahal_function',
			learn            => '_megahal_function',
			_cleanup         => '_megahal_function',
		},
		$self => [ qw(_child_closed _child_error _child_stderr _child_stdout _start shutdown _sig_chld) ],
	],
	( ref ( $options ) eq 'HASH' ? ( options => $options ) : () ),
  );

  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub _megahal_function {
  my ($kernel,$self,$state) = @_[KERNEL,OBJECT,STATE];
  my $sender = $_[SENDER]->ID();
  return if $self->{shutdown};

  my $args;

  if ( ref( $_[ARG0] ) eq 'HASH' ) {
	$args = { %{ $_[ARG0] } };
  }
  else {
	warn "first parameter must be a hashref, trying to adjust. "
		."(fix this to get rid of this message)";
	$args = { @_[ARG0..$#_] };
  }

  unless ( $args->{event} ) {
	warn "where am i supposed to send the output?";
	return;
  }


  return if $state =~ /^(do_reply|learn)$/ and !defined $args->{text};

  delete $args->{text} if $state eq 'initial_greeting' and defined $args->{text};

  delete $args->{text} if $state eq '_cleanup' and defined $args->{text};

  $args->{sender} = $sender;
  $args->{func} = $state;
  $kernel->refcount_increment( $sender => __PACKAGE__ );
  $args->{sender} = $sender;

  $self->{wheel}->put( $args ) if defined $self->{wheel};
  return;
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
	Program => \&_main,
	ProgramArgs => [ AutoSave => $self->{autosave}, Path => $self->{path} ],
	ErrorEvent => '_child_error',
	CloseEvent => '_child_closed',
	StdoutEvent => '_child_stdout',
	StderrEvent => '_child_stderr',
	StdioFilter => POE::Filter::Reference->new(),
	StderrFilter => POE::Filter::Line->new(),
	( $^O eq 'MSWin32' ? ( CloseOnCall => 0 ) : ( CloseOnCall => 1 ) ),
  );

  $kernel->sig_child( $self->{wheel}->PID, '_sig_chld' );
  return;
}

sub _sig_chld {
  $_[KERNEL]->sig_handled();
}

sub _child_closed {
  delete $_[OBJECT]->{wheel};
  return;
}

sub _child_error {
  delete $_[OBJECT]->{wheel};
  return;
}

sub _child_stderr {
  my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];
  warn $input . "\n" if $self->{debug};
  return;
}

sub _child_stdout {
  my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];
  my $sender = delete $input->{sender};
  my $event = delete $input->{event};
  $kernel->post( $sender => $event => $input );
  $kernel->refcount_decrement( $sender => __PACKAGE__ );
  return;
}

sub shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  $self->{shutdown} = 1;
  $self->{wheel}->shutdown_stdin;
  return;
}

sub _main {
  my %params = @_;
  if ( $^O eq 'MSWin32' ) {
     binmode(STDIN); binmode(STDOUT);
  }
  my $raw;
  my $size = 4096;
  my $filter = POE::Filter::Reference->new();
  my $megahal;
  eval {
	  $megahal = AI::MegaHAL->new( %params );
  };

  if ( $@ ) {
	print STDERR $@ . "\n";
	return;
  }

  while ( sysread ( STDIN, $raw, $size ) ) {
    my $requests = $filter->get( [ $raw ] );
    _process_requests( $megahal, $_, $filter ) for @{ $requests };
  }
  $megahal->_cleanup() if $params{'AutoSave'};
  $megahal->DESTROY;
}

sub _process_requests {
  my ($megahal,$req,$filter) = @_;

  my $func = $req->{func};
  $req->{reply} = $megahal->$func( $req->{text} );
  my $response = $filter->put( [ $req ] );
  print STDOUT @$response;
}

qq[You talking to me];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::AI::MegaHAL - A non-blocking wrapper around AI::MegaHAL.

=head1 VERSION

version 1.20

=head1 SYNOPSIS

    use POE qw(Component::AI::MegaHAL);

    my $poco = POE::Component::AI::MegaHAL->spawn( autosave => 1, debug => 0,
						      path => '.', options => { trace => 0 } );

    POE::Session->create(
	package_states => [
		'main' => [ qw(_start _got_reply) ],
	],
    );

    $poe_kernel->run();
    exit 0;

    sub _start {
	$_[KERNEL]->post( $poco->session_id() => do_reply => { text => 'What is a MegaHAL ?', event => '_got_reply' } );
	undef;
    }

    sub _got_reply {
	print STDOUT $_[ARG0]->{reply} . "\n";
	$_[KERNEL]->post( $poco->session_id() => 'shutdown' );
	undef;
    }

=head1 DESCRIPTION

POE::Component::AI::MegaHAL provides a non-blocking wrapper around L<AI::MegaHAL>.

=head1 METHODS

=over

=item C<spawn>

Accepts a number of arguments:

  'autosave' and 'path' are passed to AI::MegaHAL;
  'debug' sets the debug mode;
  'options' is a hashref of parameters to pass to the component's POE::Session;
  'alias', is supported for using POE::Kernel aliases;

=item C<session_id>

Returns the component session id.

=back

=head1 INPUT

These are the events that we'll accept.

All megahal related events accept a hashref as the first parameter. You must specify 'event' as the event in your session where you
want the response to go. See the example in the SYNOPSIS.

The 'shutdown' event doesn't require any parameters.

=over

=item C<intial_greeting>

Solicits the initial greeting returned by the brain on start-up.

=item C<do_reply>

Submits text to the brain and solicits a reply.
In the hashref you must specify 'text' with the data you wish to submit to the L<AI::MegaHAL> object.

=item C<learn>

Submits text to the brain without soliciting a reply.
In the hashref you must specify 'text' with the data you wish to submit to the L<AI::MegaHAL> object.

=item C<_cleanup>

Saves the megahal brain to file.

=item C<shutdown>

Shuts the component down gracefully. Any pending requests will be serviced and return events dispatched.

=back

=head1 OUTPUT

Events generated by the component in response to the above input will have a hashref as ARG0. $hashref->{reply}
will contain the applicable response from the brain.

=head1 SEE ALSO

L<AI::MegaHAL>

L<http://megahal.sourceforge.net/>

L<POE>

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

David Davis <xantus@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
