=head1 NAME

POE::Component::Server::SMTP - SMTP Protocol Implementation

=head1 SYNOPSIS

  use POE;
  use POE::Component::Server::SMTP;

  POE::Component::Server::SMTP->spawn(
    Port => 2525,
  	InlineStates => {
  		HELO => \&smtp_helo,
  		QUIT => \&smtp_quit,
  	},
  );

  sub smtp_helo {
    my ($heap) = $_[HEAP];
    my $client = $heap->{client};

    $client->put( SMTP_OK, 'Welcome.' );
  }

  sub smtp_quit {
    my ($heap) = $_[HEAP];
    my $client = $heap->{client};

    $client->put( SMTP_QUIT, 'Good bye!' );
    $heap->{shutdown_now} = 1;
  }

  $poe_kernel->run;
  exit 0;

=head1 DESCRIPTION

POE::Component::Server::TCP implements the SMTP protocol for the server.
I won't lie, this is very low level.  If you want to support any command
other than HELO and QUIT, you'll have to implement it yourself, and define
it in your C<InlineStates>, C<PackageStates>, or C<ObjectStates>.

This module uses L<POE::Session::MultiDispatch|POE::Session::MultiDispatch>
to allow for "Plugins" using C<PackageStates> and C<ObjectStates>.

Also, as of this release, L<POE|POE> version 0.24 is out.  This module
relies on a CVS version of POE.

=cut

package POE::Component::Server::SMTP;
use strict;

use Exporter;
use Mail::Internet;
use Sys::Hostname qw[hostname];
use POE qw[
	Wheel::ReadWrite
	Driver::SysRW
	Filter::SMTP
	Filter::Line
	Session::MultiDispatch
	Component::Server::TCP
];

use vars qw[$VERSION @ISA @EXPORT];
$VERSION = '1.6';
@ISA     = qw[Exporter];
@EXPORT  = qw[
	SMTP_SYTEM_STATUS SMTP_SYSTEM_HELP SMTP_SERVICE_READY SMTP_QUIT
	SMTP_OK SMTP_WILL_FORWARD SMTP_CANNOT_VRFY_USER

	SMTP_START_MAIL_INPUT

	SMTP_NOT_AVAILABLE SMTP_SERVICE_UNAVAILABLE
	SMTP_LOCAL_ERROR SMTP_NO_STORAGE

	SMTP_SYNTAX_ERROR SMTP_ARG_SYNTAX_ERROR SMTP_NOT_IMPLEMENTED
	SMTP_BAD_SEQUENCE SMTP_ARG_NOT_IMPLEMENTED SMTP_UNAVAILABLE
	SMTP_USER_NOT_LOCAL SMTP_QUOTA_LIMIT SMTP_MAILBOX_ERROR
	SMTP_NO_SERVICE SMTP_TRANSACTION_FAILED
];

=head2 Constants

This module exports a bunch of constants by default.

	SMTP_SYTEM_STATUS SMTP_SYSTEM_HELP SMTP_SERVICE_READY SMTP_QUIT
	SMTP_OK SMTP_WILL_FORWARD SMTP_CANNOT_VRFY_USER

	SMTP_START_MAIL_INPUT

	SMTP_NOT_AVAILABLE SMTP_SERVICE_UNAVAILABLE
	SMTP_LOCAL_ERROR SMTP_NO_STORAGE

	SMTP_SYNTAX_ERROR SMTP_ARG_SYNTAX_ERROR SMTP_NOT_IMPLEMENTED
	SMTP_BAD_SEQUENCE SMTP_ARG_NOT_IMPLEMENTED SMTP_UNAVAILABLE
	SMTP_USER_NOT_LOCAL SMTP_QUOTA_LIMIT SMTP_MAILBOX_ERROR
	SMTP_NO_SERVICE SMTP_TRANSACTION_FAILED

If you don't know what these mean, see the source.

=cut

sub SMTP_SYTEM_STATUS          { 211 }
sub SMTP_SYSTEM_HELP           { 211 }
sub SMTP_SERVICE_READY         { 220 }
sub SMTP_QUIT                  { 221 }
sub SMTP_OK                    { 250 }
sub SMTP_WILL_FORWARD          { 251 }
sub SMTP_CANNOT_VRFY_USER      { 252 }

sub SMTP_START_MAIL_INPUT      { 354 }

sub SMTP_NOT_AVAILABLE         { 421 }
sub SMTP_SERVICE_UNAVAILABLE   { 450 }
sub SMTP_LOCAL_ERROR           { 451 }
sub SMTP_NO_STORAGE            { 452 }

sub SMTP_SYNTAX_ERROR          { 500 }
sub SMTP_ARG_SYNTAX_ERROR      { 501 }
sub SMTP_NOT_IMPLEMENTED       { 502 }
sub SMTP_BAD_SEQUENCE          { 503 }
sub SMTP_ARG_NOT_IMPLEMENTED   { 504 }
sub SMTP_UNAVAILABLE           { 550 }
sub SMTP_USER_NOT_LOCAL        { 551 }
sub SMTP_QUOTA_LIMIT           { 552 }
sub SMTP_MAILBOX_ERROR         { 553 }
sub SMTP_NO_SERVICE            { 554 }
sub SMTP_TRANSACTION_FAILED    { 554 }

=head2 spawn( %args )

Create a new instance of the SMTP server.  The argument list
follows.

=over 4

=item Alias

The alias name for this session.

=item Address

The address to bind to. If you don't do this you run the risk of
becomming a relay.

=item Hostname

The host name to use when identifying the SMTP server.

=item Port

The port to listen and accept connections on.

=item PackageStates 

Passed directly to POE::Session::MultiDispatch.

=item ObjectStates 

Passed directly to POE::Session::MultiDispatch.

=item InlineStates 

Passed directly to POE::Session::MultiDispatch.

=back

=cut

sub spawn {
	my ($class, %args) = @_;

	$args{Alias}         ||= 'smtpd';
	$args{Hostname}      ||= hostname();
	$args{Port}          ||= 25;

	$args{PackageStates} ||= [ ];
	$args{ObjectStates}  ||= [ ];
	$args{InlineStates}  ||= { };

	POE::Component::Server::TCP->new(
                Address            => $args{Address},
		Alias              => $args{Alias},
		Port               => $args{Port},
		SessionType        => 'POE::Session::MultiDispatch',
#		SessionParams      => [ options => { debug => 1, trace => 1 } ],
		Error              => \&smtpd_server_error,
		ClientConnected    => \&smtpd_client_connected,
		ClientDisconnected => \&smtpd_client_disconnect,
		ClientInput        => \&smtpd_client_input,
		ClientFlushed      => \&smtpd_client_flushed,
		ClientError        => \&smtpd_client_error,
		ClientFilter       => [ 'POE::Filter::SMTP' ],
		PackageStates      => $args{PackageStates},
		ObjectStates       => $args{ObjectStates},
		InlineStates       => {
# these are shown below for reference and may move elsewhere
#			send_banner => \&smtpd_send_banner,
#			HELO        => \&smtpd_HELO,
#			QUIT        => \&smtpd_QUIT,
#			DATA        => \&smtpd_DATA,
#			gotDATA     => \&smtpd_gotDATA,
			_default    => \&smtpd_default,
			%{$args{InlineStates}},
		},
		Args => [ \%args ],
	);

}

sub smtpd_client_connected {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	my ($client) = $heap->{client};

  $heap->{args} = $args;

	$kernel->yield( 'send_banner' );
}

sub smtpd_client_disconnect {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	$kernel->yield( 'do_disconnect' );
}

sub smtpd_client_input {
	my ($kernel, $heap,    $input) = @_[KERNEL, HEAP, ARG0];
	
	if ( $heap->{+SMTP_START_MAIL_INPUT} ) {
		my $client = $heap->{client};
		if ( $input eq '.' ) {
			$heap->{+SMTP_START_MAIL_INPUT} = 0;
		  $client->set_input_filter( POE::Filter::SMTP->new() );
		  $kernel->yield( gotDATA => $heap->{data_input} );
		} else {
			push @{$heap->{data_input}}, $input;
		}
	} else {
		my ($client, $command, $data)  = ( $heap->{client}, @{$input} );
		$kernel->yield( $command => $command => $data );
	}
}

sub smtpd_client_flushed {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	delete $heap->{client} if $heap->{shutdown_now};
}

sub smtpd_client_error {
	my ($kernel, $heap, $syscall_name, $error_number, $error_string) =
		@_[KERNEL, HEAP, ARG0 .. ARG2];
}

sub smtpd_server_error {
	my ($kernel, $heap, $syscall_name, $error_number, $error_string) =
		@_[KERNEL, HEAP, ARG0 .. ARG2];
}

=head2 Events

There are only three builtin events.  This way, the default
POE::Component::Server::SMTP distribution is completley secure.  Unless
otherwise noted, event names corrispond to the uppercase version of the
verb supplied from the client during an SMTP connection (HELO, VRFY, RCPT).

Any input supplied after the command verb will be available to the
event handler in C<$_[ARG1]>, the command name itself is available in
C<$_[ARG0]>.

=over 4

=item send_banner

This event is triggered when a client connects and it's time to send
a banner.  This can be supplied in  your own
C<send_banner> event in your C<InlineStates>.

=cut

sub smtpd_send_banner {
	my ($kernel, $heap) =
		@_[KERNEL, HEAP];
	my $client = $heap->{client};

	my $banner = join( ' ',
		                 $heap->{args}->{Hostname},
		                 'ESMTP',
		                 __PACKAGE__,
		                 'v'.$POE::Component::Server::SMTP::VERSION );

	$client->put( SMTP_SERVICE_READY, $banner );
}

=item HELO

This event is triggered when a client sends a HELO command.
This can be supplied in  your own
C<HELO> event in your C<InlineStates>.

=cut

sub smtpd_HELO {
	my ($kernel, $heap, $host) =
		@_[KERNEL, HEAP, ARG1];
	my $client = $heap->{client};

	if ( $host && $host eq $heap->{args}->{Hostname} ) {
		$client->put( SMTP_OK, qq[$heap->{args}->{Hostname} Would you like to play a game?] );
	} else {
		$client->put( SMTP_ARG_SYNTAX_ERROR, qq[Syntax: HELO hostname] );
	}
}

=item QUIT

This event is triggered when a client sends a QUIT command.
This can be supplied in  your own
C<QUIT> event in your C<InlineStates>.

This event should always set C<$heap->{shutdown_now}> to a true value.

=back

=cut

sub smtpd_QUIT {
	my ($kernel, $heap) =
		@_[KERNEL, HEAP];
	my $client = $heap->{client};

	$client->put( SMTP_QUIT, q[How about a nice game of chess?] );
	$heap->{shutdown_now} = 1;
}

=pod

In the source of this module there are two example handlers for handling
the C<DATA> event.  The C<DATA> event is kind of tricky, so refer to the
C<smtpd_DATA> and C<smtpd_gotDATA> subroutines in the source.

=cut

sub smtpd_DATA {
	my ($kernel, $heap) =
		@_[KERNEL, HEAP];
	my $client = $heap->{client};

	$heap->{+SMTP_START_MAIL_INPUT} = 1;

	$client->put( SMTP_START_MAIL_INPUT, q[You selected Global Thermo Nuclear War.] );
	
	$client->set_input_filter( POE::Filter::Line->new( Literal => POE::Filter::SMTP::CRLF ) );
}

sub smtpd_gotDATA {
	my ($kernel, $heap) =
		@_[KERNEL, HEAP];
	my $client = $heap->{client};
	my $data   = join POE::Filter::SMTP::CRLF, @{$heap->{data_input}};
print $data;
	$client->put( SMTP_OK, q[Got data.] );
}

=pod

=item on_disconnect

This event is called when the client disconnects. Specifically, when
POE::Component::Server::TCP throws the C<ClientDisconnected> state. You
can't always rely on an SMTP client calling C<QUIT>, so use this for
garbage collection or handling an unexpected end of session.

=cut

=pod

Any event that it triggered from the client that the server doesn't know
how to handle will be passed to the C<_default> handler.  This handler
will return C<SMTP_NOT_IMPLEMENTED>, unless you override it using
C<InlineStates> and do something else.

=cut

sub smtpd_default {
	my ($kernel, $heap) =
		@_[KERNEL, HEAP];
	my $client = $heap->{client};

	$client->put( SMTP_NOT_IMPLEMENTED, q[Error: command not implemented] );
}

1;

__END__

=pod

=head1 BUGS

No doubt.

It should be noted that this is extremley early code.  After all, it
relies on features of POE that haven't even been released.  Anything
could change!

See http://rt.cpan.org to report bugs.

=head2 Known Issues

The following is what I would consider known issues.

=over 4

=item

The only way to override builtin event handlers is using C<InlineStates>.
The truth is that there probably shouldn't be any builtin handlers.  They
will probably go away soon.

=item

Documentation and Tests are lacking.

=item

There is no POE::Component::Client::SMTP yet, though that's really
a TODO item.

=back

=head1 AUTHOR

Casey West <casey@geeknest.com>

=head1 THANKS

Meng Wong, and http://pobox.com/

=head1 COPYRIGHT

Copyright (c) 2003 Casey West.  All rights reserved.  This program 
is free software; you can redistribute it and/or modify it under the same 
terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<POE>.

=cut

