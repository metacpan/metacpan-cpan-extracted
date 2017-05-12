#---------------------------------------------------------------------
package Telephony::Asterisk::AMI;
#
# Copyright 2015 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 31 Oct 2015
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Simple Asterisk Manager Interface client
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;


use Carp ();
use IO::Socket::IP ();

our $VERSION = '0.006';
# This file is part of Telephony-Asterisk-AMI 0.006 (December 26, 2015)

my $EOL = "\r\n";

#=====================================================================


sub new {
  my $class = shift;
  my $args = (@_ == 1) ? shift : { @_ };

  my $self = bless {
    Debug_FH => ($args->{Debug_FH} || ($args->{Debug} ? *STDERR : undef)),
    Event_Callback => $args->{Event_Callback},
    Host => $args->{Host} || 'localhost',
    Port => $args->{Port} || 5038,
    ActionID => $args->{ActionID} || 1,
  }, $class;

  for my $key (qw(Username Secret)) {
    defined( $self->{$key} = $args->{$key} )
        or Carp::croak("Required parameter '$key' not defined");
  }

  $self;
} # end new
#---------------------------------------------------------------------


sub connect {
  my $self = shift;

  # Open a socket to Asterisk.
  #   IO::Socket::IP->new reports error in $@
  local $@;

  $self->{socket} = IO::Socket::IP->new(
    Type => IO::Socket::IP::SOCK_STREAM(),
    PeerHost => $self->{Host},
    PeerService => $self->{Port},
  );

  unless ($self->{socket}) {
    $self->{error} = "Connection failed: $@";
    return undef;
  }

  # Verify that we've connected to Asterisk Call Manager
  my $id = readline($self->{socket});

  unless (defined $id) {
    $self->{error} = "Connection closed without input: $!";
    undef $self->{socket};
    return undef;
  }

  chomp $id;
  print { $self->{Debug_FH} } "<< $id\n" if $self->{Debug_FH};

  if ($id =~ m!^Asterisk Call Manager/(.+)!) {
    $self->{protocol} = $1;
  } else {
    $self->{error} = "Unknown Protocol";
    undef $self->{socket};
    return undef;
  }

  # Automatically log in using Username/Secret
  my $response = $self->action({
    Action => 'Login',
    Username => $self->{Username},
    Secret => $self->{Secret},
  });

  # If login failed, set error
  unless ($response->{Response} eq 'Success') {
    $self->{error} = "Login failed: $response->{Message}";
    undef $self->{socket};
    return undef;
  }

  # Login successful
  1;
} # end connect
#---------------------------------------------------------------------


sub disconnect {
  my $self = shift;

  my $response = $self->action({Action => 'Logoff'});

  # If logoff failed, set error
  unless ($response->{Response} eq 'Goodbye') {
    $self->{error} = "Logoff failed: $response->{Message}";
    undef $self->{socket};
    return undef;
  }

  unless ($self->{socket}->close) {
    $self->{error} = "Closing socket failed: $!";
    undef $self->{socket};
    return undef;
  }

  undef $self->{socket};

  # Logoff successful
  1;
} # end disconnect
#---------------------------------------------------------------------


sub action {
  my $self = shift;

  # Send the request to Asterisk
  my $id = $self->send_action(@_) or return {
    Response => 'Error',
    Message => $self->{error},
  };

  # Read responses until we get the response to this action
  while (1) {
    my $response = $self->read_response;

    # If this is the response to the action we just sent,
    # or there was an error, return it.
    no warnings 'uninitialized';
    if (($response->{ActionID} eq $id) ||
        ($response->{Response} eq 'Error')) {
      return $response;
    }

    # If there is an event callback, send it this event
    if ($self->{Event_Callback}) {
      $self->{Event_Callback}->($response);
    }
  } # end infinite loop waiting for response
} # end action
#---------------------------------------------------------------------


sub send_action {
  my $self = shift;
  my $act = (@_ == 1) ? shift : { @_ };

  Carp::croak("Required parameter 'Action' not defined") unless $act->{Action};

  # Check that the connection is open
  unless ($self->{socket}) {
    $self->{error} = "Not connected to Asterisk!";
    return undef;
  }

  # Assemble the message to send to Asterisk
  my $id = $self->{ActionID}++;
  my $message = "ActionID: $id$EOL";

  for my $key (sort keys %$act) {
    if (ref $act->{$key}) {
      $message .= "$key: $_$EOL" for @{ $act->{$key} };
    } else {
      $message .= "$key: $act->{$key}$EOL";
    }
  }

  $message .= $EOL;             # Message ends with blank line

  # If debugging, print out the message before sending it
  if ($self->{Debug_FH}) {
    my $debug = $message;
    $debug =~ s/\r//g;
    $debug =~ s/^/>> /mg;
    print { $self->{Debug_FH} } $debug;
  }

  # Send the request to Asterisk
  unless (print { $self->{socket} } $message) {
    $self->{error} = "Writing to socket failed: $!";
    return undef;
  }

  $id;
} # end send_action
#---------------------------------------------------------------------


sub read_response {
  my $self = shift;

  # Check that the connection is open
  my $socket = $self->{socket};
  unless ($socket) {
    return {
      Response => 'Error',
      Message => $self->{error} = "Not connected to Asterisk!",
    };
  }

  # Read a response terminated by a blank line
  local $/ = $EOL;
  my $debug_fh = $self->{Debug_FH};
  my ($line, %response);
  undef $!;

  while ($line = <$socket>) {
    chomp $line;
    print $debug_fh "<< $line\n" if $debug_fh;

    return \%response unless length $line;

    # Remove the key from the "Key: Value" line
    # If the line is not in that format, ignore it.
    $line =~ s/^([^:]+): // or next;

    if (not exists $response{$1}) {
      # First occurrence of this key, save as string
      $response{$1} = $line;
    } elsif (ref $response{$1}) {
      # Third or more occurrence of this key, append to arrayref
      push @{ $response{$1} }, $line;
    } else {
      # Second occurrence of this key, convert to arrayref
      $response{$1} = [ $response{$1}, $line ];
    }
  } # end while reading from $socket

  # There was a communication failure; return an error.
  return {
    Response => 'Error',
    Message => $self->{error} = "Reading from socket failed: $!",
  };
} # end read_response

#---------------------------------------------------------------------


sub error { shift->{error} }

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

Telephony::Asterisk::AMI - Simple Asterisk Manager Interface client

=head1 VERSION

This document describes version 0.006 of
Telephony::Asterisk::AMI, released December 26, 2015.

=head1 SYNOPSIS

  use Telephony::Asterisk::AMI ();

  my $ami = Telephony::Asterisk::AMI->new(
    Username => 'user',
    Secret => 'password',
  );

  $ami->connect or die $ami->error;

  my $response = $ami->action(Action => 'Ping');

  $ami->disconnect or die $ami->error;

=head1 DESCRIPTION

Telephony::Asterisk::AMI is a simple client for the Asterisk Manager
Interface.  It's better documented and less buggy than
L<Asterisk::Manager>, and has fewer prerequisites than
L<Asterisk::AMI>.  It uses L<IO::Socket::IP>, so it should support
either IPv4 or IPv6.

If you need a more sophisticated client (especially for use in an
event-driven program), try Asterisk::AMI.

=head1 METHODS


=head2 Constructor


=head3 new

  $ami = Telephony::Asterisk::AMI->new(%args);

Constructs a new C<$ami> object.  The C<%args> may be passed as a
hashref or a list of S<C<< key => value >>> pairs.

This does not do any network communication; you must call L</connect>
to open the connection before doing anything else.

The parameters are:

=over

=item C<Username>

The AMI username to use when logging in. (required)

=item C<Secret>

The AMI secret (password) to use when logging in. (required)

=item C<Host>

The hostname to connect to.
You can also specify C<hostname:port> as a single string.
(default: localhost).

=item C<Port>

The port number to connect to (if no port was specified with C<Host>).
(default: 5038)

=item C<ActionID>

The ActionID to start at.  Each call to L</action> increments the ActionID.
(Note: The L</connect> & L</disconnect> methods also consume an ActionID for
the implicit Login & Logoff actions.)
(default: 1)

=item C<Debug>

If set to a true value, sets C<Debug_FH> to C<STDERR>
(unless it was already set to a different value).
(default: false)

=item C<Debug_FH>

A filehandle to write a transcript of the communications to.
Lines sent to Asterisk are prefixed with C<<< >> >>>, and lines
received from Asterisk are prefixed with C<<< << >>>.
(default: no transcript)

=item C<Event_Callback>

A coderef that is called when an event is received from Asterisk while
the L</action> method is waiting for a response.  The event data is
passed as a hashref, just like the return value of the C<action>
method.  You MUST NOT call any methods on C<$ami> from inside the
callback.
(default: events are ignored)

=back

The constructor throws an exception if a required parameter is
omitted.


=head2 Main Methods


=head3 connect

  $success = $ami->connect;

Opens the connection to Asterisk and logs in.
C<$success> is true if the login was successful, or C<undef> on error.
On failure, you can get the error message with C<< $ami->error >>.


=head3 disconnect

  $success = $ami->disconnect;

Logs off of Asterisk and closes the connection.
C<$success> is true if the logoff was successful, or C<undef> on error.
On failure, you can get the error message with C<< $ami->error >>.

After a successful call to C<disconnect>, you may call C<connect>
again to reestablish the connection.


=head3 action

  $response = $ami->action(%args);

Sends an action request to Asterisk and returns the response.  The
C<%args> may be passed as a hashref or a list of S<C<< key => value
>>> pairs, where the keys are the Asterisk field names.  To create
more than one instance of a field, make the value an arrayref.

The only required key is C<Action>.  (Asterisk may require other keys
depending on the value of C<Action>, but that is not enforced by this
module.)

Do not pass an C<ActionID> in C<%args>.  The ActionID is provided
automatically.

The C<$response> is a hashref formed from Asterisk's response in the
same format as C<%args>.  It will have a C<Response> key whose value
is either C<Success> or C<Error>.  Unless it's an error response, it
will also have an C<ActionID> key whose value is the ActionID assigned
to it.  (An error response might or might not have an ActionID.)

Any events that are received while waiting for the response to the
action are dispatched to the C<Event_Callback> (if any).  If no
callback was provided, events are discarded.

If you have not called the C<connect> method (or it failed), calling
C<action> will return a manufactured Error response with Message
"Not connected to Asterisk!" and set C<< $ami->error >>.

If communication with Asterisk fails, it will return a manufactured
Error response with Message "Writing to socket failed: %s" or
"Reading from socket failed: %s" and set C<< $ami->error >>.


=head3 error

  $error_message = $ami->error;

If communication with Asterisk fails, this method will return an error
message describing the problem.

If Asterisk returns "Response: Error" for some action, that does not
set C<< $ami->error >>.  The exceptions are the automatic Login and Logoff
actions performed by the L</connect> and L</disconnect> methods, which
do set C<error> on failure.

It returns C<undef> if there has been no communication error.


=head2 Low-Level Methods

You shouldn't normally need to use these methods, but sometimes you
need more control over the communication with Asterisk.



=head3 send_action

  $actionid = $ami->send_action(%args);

Sends an action request to Asterisk and returns the ActionID.  The
C<%args> are the same as for L</action>.

Do not pass an C<ActionID> in C<%args>.  The ActionID is provided
automatically and returned.

If you have not called the C<connect> method (or it failed), calling
C<send_action> will return C<undef> and set C<< $ami->error >> to
"Not connected to Asterisk!".

If communication with Asterisk fails, it will return C<undef> and set
C<< $ami->error >> to "Writing to socket failed: %s".


=head3 read_response

  $response = $ami->read_response;

Reads a single message from Asterisk.  Blocks until a message arrives.
The C<action> method waits for the response, so C<read_response>
is only useful for reading events (or if you used the low-level
C<send_action> method).

It returns a hashref in the same format as the return value of the
C<action> method.  See that for details.

Note that events received by C<read_response> are not delivered to the
C<Event_Callback> (if any).  The callback is used only for events
that are received during the execution of the C<action> method.

If you have not called the C<connect> method (or it failed), calling
C<read_response> will return a manufactured Error response with Message
"Not connected to Asterisk!" and set C<< $ami->error >>.

If communication with Asterisk fails, it will return a manufactured
Error response with Message "Reading from socket failed: %s" and set
C<< $ami->error >>.

=head1 SEE ALSO

L<https://wiki.asterisk.org/wiki/display/AST/Home>

L<Asterisk::AMI> is a more sophisticated AMI client better suited for
event-driven programs.

If you're using L<POE>, you may want
L<POE::Component::Client::Asterisk::Manager>.

=head1 DIAGNOSTICS

=over

=item C<Required parameter %s not defined>

You omitted a required parameter from a method call.


=back

=head1 CONFIGURATION AND ENVIRONMENT

Telephony::Asterisk::AMI requires no configuration files or environment variables.

=head1 DEPENDENCIES

Telephony::Asterisk::AMI depends on L<IO::Socket::IP>, which became a
core module with Perl 5.20.  There are no other non-core dependencies.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Telephony-Asterisk-AMI AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Telephony-Asterisk-AMI >>.

You can follow or contribute to Telephony-Asterisk-AMI's development at
L<< https://github.com/madsen/Telephony-Asterisk-AMI >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
