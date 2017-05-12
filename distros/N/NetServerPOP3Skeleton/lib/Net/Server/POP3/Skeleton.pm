package Net::Server::POP3::Skeleton;

=head1 NAME

Net::Server::POP3::Skeleton - A simple skeleton POP3 server

=head1 SYNOPSIS

  package MyServer;
  use base 'Net::Server::POP3::Skeleton';

  sub user {
    my $self = shift;
    my $name = shift;

    unless(defined $name) {
      $client->senderr("missing argument");
      return;
    }

    $self->set('username', $name);
    $self->sendok("username accepted, send password");
  }

  sub pass {
    my $self = shift;
    my $pass = shift;
    my $name = $self->get('username');

    # PASS not allowed before USER
    return $self->unknown() unless defined $name;

    return $self->senderr('invalid username or password')
      unless $Auth{$name} eq $pass;

    $self->state('TRANS');
    $self->sendok();
  }

  package main;

  $server = MyServer->new(
    greeting => "POP3 My server ready",
  );

  $server->run();

=head1 DESCRIPTION

This module implements a bare-bones skeleton POP3 server.  It is
intended as a base class.  You should inherit from this class
(which, in turn, inherits from
L<Net::Server::Fork|Net::Server::Fork>).  The only POP3 command
implemented by this module is the QUIT command.  All others
should be implemented by your code as methods.

The purpose of this module is for easily creating non-standard
POP3 servers in Perl.  If you want a normal POP3 server (ie, one
that simply serves emails from an MBOX or MailDirs file), you
would probably be better off using one of the pre-built, faster
C-based servers.  If, on the other hand, you want to create a
specialized POP3 server that, for instance, generates the content
of the messages dynamically based on data from a website, this
module is what you want.

=head1 OPTIONS

When C<use>ing this module, you can specify an import option of
C<nonFork>.  This will cause the module to inherit from
L<Net::Server|Net::Server> instead of
L<Net::Server::Fork|Net::Server::Fork>.  See L<CAVEATS> for more
information

=cut

use warnings;
use strict;

use 5.006;
our $VERSION = 1.0;

our $EOL  = "\015\012";
our $EOLP = qr/(?:\015?\012|\012?\015)/;

our %Defaults = (
  # The docs for Net::Server say you can just put the options
  # in the top level of the hash, but that doesn't actually
  # work.  You have to put it in a hash ref under the 'server'
  # key.  Also, the port option must be an array ref, which
  # isn't mentioned either.
  server => {
    port     => [ 110 ],
    debug    => 0,
  },
  # We use the package name in consideration of
  # potential issues with inheritence later.
  (__PACKAGE__) => {
    serverdata => {
      timeout  => 60,
      transerr => 0,
      caperr   => 1,
      greeting => "POP3 Net::Server::POP3::Skeleton ready",
      goodbye  => "goodbye",
      AllowedCommands => {
        AUTHORIZATION => {
          user => undef,
          pass => undef,
          quit => undef,
        },
        TRANSACTION => {
          stat => undef,
          list => undef,
          retr => undef,
          dele => undef,
          noop => undef,
          rset => undef,
          top  => undef,
          uidl => undef,
          quit => undef,
        },
      },
    },
  },
);

our @ISA;
our $NonFork = 0;

use IO::Select;
use Net::Server;
use Carp;

sub import {
  my $module = shift;

  for my $opt (@_) {
    $NonFork = 1 if(lc($opt) eq 'nonfork');
  }
}

INIT {
  if($NonFork) {
    @ISA = ('Net::Server');
  } else {
    if($^O =~ /win32/i and $^V lt v5.8.0) {
      die <<"EOD";
You must have perl v5.8.0 to use the forking personality
of this module on a Win32 platform.  Please see the CAVEATS
section of the Net::Server::POP3::Skeleton documentation.
EOD
    }
    require Net::Server::Fork;
    @ISA = ('Net::Server::Fork');
  }
}

=head1 METHODS

=head2 new [OPTIONS]

Creates a new instance of the server.  This method can be inherited.

The following options are recognized:

=over 4

=item port

Port to listen on.  Defaults to 110.

=item greeting

Greeting to send clients when they connect.
Defaults to "POP3 Net::Server::POP3::Skeleton ready"

=item goodbye

Message sent to clients when they sign off.
Defaults to "goodbye"

=item debug

Server debug flag.  Set to enable logging of extra
information, and printing of some debug data to STDERR.
Defaults to 0.

=item timeout

Number of seconds to wait after receiving data from the
client before terminating the connection.  This option
is especially important when using the L<nonfork> option,
since a client who leaves the connection open prohibits
others from connecting.  Set to a false value to disable
timeout.  This uses C<alarm>.
Defaults to 60.

=item transerr

Transmit uncaught error messages to the client.
If this option is set, uncaught, fatal error messages
in the command handlers are passed along to the client.
Otherwise, a generic message is sent.
Defaults to 0.

Note that setting this option could present a security
risk, as debugging info might be given to a potential
attacker.  It is recommended to leave this option disabled.

=item caperr

Capture otherwise fatal errors in command handlers.
If this option is set, fatal errors in the command
handlers are caught so that they don't bring down
the server.  Otherwise, the program halts on an
uncaught error.
Defaults to 1.

=back

=cut
sub new {
  my $class = shift;
  my %opts  = @_;

  my %self = %{\%Defaults};

  my $self = bless \%self, $class;

  while(my ($key, $val) = each %opts) {
    if(defined $self->_get_server_data($key)) {
      $self->_set_server_data($key, $val);
    } else {
      $val = [$val] if $key eq 'port' or $key eq 'allow' or $key eq 'deny';
      $self->{server}{$key} = $val;
    }
  }

  return $self;
}


=head2 process_request

Handles connections accepted by Net::Server.

Commands are read from the client and dispatched
appropriately (see L<"COMMANDS">) until either the
client disconnects, or C<$obj-E<gt>{hasquit}> becomes
true (usually set by the QUIT command).

This method should be considered internal and should
not be called (it will be called automatically by
L<Net::Server|Net::Server>).  You probably will not
ever need to overload this method.

=cut
sub process_request {
  my $self = shift;

  $self->state('CONNECT');
  if($self->can('connect')) {
    eval { $self->connect() };
    if(my $err = $@) {
      $self->log(0, $err);
      die($err) unless $self->_get_server_data('caperr');
    }
  }

  $self->state('AUTH');
  $self->sendok($self->_get_server_data('greeting'));

  $self->_set_server_data('hasquit', 0);

  my $select = IO::Select->new(\*STDIN);
  while(
      not $self->_get_server_data('hasquit')
      and $select->can_read($self->_get_server_data('timeout'))
      and defined(my $line = <STDIN>)
  ) {
    $line =~ s/$EOLP//;
    print STDERR "Received following command: `$line'\n"
      if $self->{server}{debug};
    my ($cmd, $args) = split /\s+/, $line, 2;
    $cmd = $self->_normalize_cmd_name($cmd);

    unless(exists
        $self->_get_server_data('AllowedCommands')->{$self->state()}{$cmd}
    ) {
      $self->unknown();
      next;
    }

    my $method = $self->can($cmd) || 'unimplemented';

    eval {
      $self->$method($args);
    };

    if(my $err = $@) {
      $self->log(0, $err);

      if($self->_get_server_data('transerr')) {
        $self->senderr($err);
      } else {
        $self->senderr("An error occured trying to execute `\U$cmd'");
      }

      die($err) unless $self->_get_server_data('caperr');
    }
  }

  unless($self->_get_server_data('hasquit')) {
    $self->senderr("Connection timed out");
  }

  $self->state('DISCONNECT');
  if($self->can('disconnect')) {
    eval { $self->disconnect() };
    if(my $err = $@) {
      $self->log(0, $err);
      die($err) unless $self->_get_server_data('caperr');
    }
  }
}

=head2 state [NEWSTATE]

Set or return the current server state.

To change the server's state, pass the new state
to this method.  States can be upper, lower, or mixed
case, and the AUTHORIZATION and TRANSACTION states
may be abbreviated as AUTH and TRANS, respectively.

The new (or current if no new state is passed) is returned.
The returned state is always the full state name, and is
always upper case.

See L<"STATES"> for more information.

=cut
sub state {
  my $self = shift;
  $self->_set_server_data('state', $self->_normalize_state_name(shift)) if @_;

  return $self->_get_server_data('state');
}

=head2 add_command STATE[[, STATE]...], COMMAND

Example:
  $server->add_command(state => 'auth', command => 'hello');

Add a new command to the server's list of allowed commands.

You must used named-argument notation (see example above),
and specify at B<least> one state, and B<one> command.
The command will then be allowed in all of the states given.

Neither the state nor command name are case-sensitive.

Note that all the standard POP3 commands are already in
the allowed commands list, so this method should only
be called to add new, non-standard commands.

=cut
sub add_command {
  my $self  = shift;
  my $class = ref $self || __PACKAGE__;

  croak "Odd number of arguments to $class->add_command()" if(@_ % 2);

  my @states;
  my $command;
  while(my ($key, $val) = splice @_, 0, 2) {
    if(lc($key) eq 'state') {
      push @states, $self->_normalize_state_name($val);
    } elsif(lc($key) eq 'command') {
      croak "Only one command allowed\n  per call to $class->add_command()"
        if($command);
      $command = $self->_normalize_cmd_name($val);
    }
  }

  for my $state (@states) {
    $self->_get_server_data('AllowedCommands')->{$state}{$command} = undef
  }
}

=head2 sendok MSG

Send to the client a positive response including the
message passed to this method.  The response will be
of the form:

  +OK MSG

Where C<MSG> is the message passed.  The response
will automatically have the end-of-line added. B<Do not>
add any end-of-line characters.

=cut
sub sendok {
  my $self = shift;
  my $msg  = shift;

  if($self->{server}{debug}) {
    print STDERR "Sent response: `+OK $msg'\n";
  }

  print("+OK $msg$EOL");
}

=head2 senderr MSG

Send to the client a negative response including the
message passed to this method.  The response will be
of the form:

  -ERR MSG

Where C<MSG> is the message passed.  The response
will automatically have the end-of-line added. B<Do not>
add any end-of-line characters.

=cut
sub senderr {
  my $self = shift;
  my $msg  = shift;

  if($self->{server}{debug}) {
    print STDERR "Sent response: `-ERR $msg'\n";
  }

  print("-ERR $msg$EOL");
}

=head2 senddata MSG [DATA...]

Send to the client a positive response and some lines
of data (eg, a message list, or message body).

For example:

  chomp(@lines = <$msgfh>);
  $server->senddata('message follows', @lines);

Note that end-of-line characters will be added to each
line as it is sent, so they should be chomped.

=cut
sub senddata {
  my $self = shift;
  my $msg  = shift;

  $self->sendok($msg);
  $self->send(@_, '.');
}

=head2 send MSG

Send a raw message to the client.  You should almost
always use one of the other send- methods mentioned
above.  EOL's will be added to the end of each argument.

Note that, since STDIN and STDOUT are opened to the
client socket, you could just write directly to them instead.

=cut
sub send {
  my $self = shift;

  if($self->{server}{debug}) {
    print STDERR "Sent data: `$_'\n" for @_;
  }

  print("$_$EOL") for @_;
}

=head2 close_client

Flags the client connection to be closed.  This should be
called from your QUIT handler (assuming you don't use the
one provided).

=cut
sub close_client {
  shift()->_set_server_data('hasquit', 1);
}

=head2 set NAME DATA

Stores some arbitrary data in the server object.
The data can be accessed calling the L<get()|"get NAME"> method
with NAME later.

DATA should be a single scalar value (though it can be a reference).

Returns DATA.

=cut
sub set {
  my $self = shift;
  my $name = shift;
  my $data = shift;

  $self->{(__PACKAGE__)}{userdata}{$name} = $data;
}

=head2 get NAME

Retrieves data stored earlier via L<set()|"set NAME DATA">.

=cut
sub get {
  my $self = shift;
  my $name = shift;

  return $self->{(__PACKAGE__)}{userdata}{$name};
}

sub _set_server_data {
  my $self  = shift;
  my $class = ref($self) || __PACKAGE__;
  my $name  = shift;
  @_ || croak "Missing data to $class->_set_server_data()\n"
             ."  (Did you mean $class->_get_server_data()?)";
  my $data  = shift;

  $self->{(__PACKAGE__)}{serverdata}{$name} = $data;
}

sub _get_server_data {
  my $self = shift;
  my $name = shift;

  return $self->{(__PACKAGE__)}{serverdata}{$name};
}

sub _normalize_state_name {
  my $self  = shift;
  my $state = uc(shift);

  $state = 'AUTHORIZATION' if $state eq 'AUTH';
  $state = 'TRANSACTION'   if $state eq 'TRANS';

  return $state;
}

sub _normalize_cmd_name {
  my $self = shift;
  my $cmd  = lc(shift);
  return $cmd;
}


#***********  Default command handlers  ***********#

sub quit {
  my $self = shift;

  $self->sendok($self->_get_server_data('goodbye'));

  $self->state('UPDATE');
  eval { $self->commit(@_) if $self->can('commit') };

  $self->close_client();
}

sub unknown {
  my $self = shift;

  $self->senderr("unknown ".$self->state()." state command");
}

sub unimplemented {
  my $self = shift;

  $self->senderr("command unimplemented");
}

# Allow the module to be run directly for debugging
__PACKAGE__->new()->run() unless caller;
1;

=head1 STATES

The server has four possible states: CONNECT, AUTHORIZATION,
TRANSACTION, UPDATE, and DISCONNECT.

When a client connects to the server, it begins in the CONNECT
state.  C<$obj->E<gt>connect()> is called, if implemented, and
the state is then switched to AUTHENTICATION.  When the user is
authenticated, the state should then move into the TRANSACTION
state.

If the user enters the QUIT command, the server will move into
the UPDATE state and call C<$obj-E<gt>commit()>, which you should
implement (see L<"COMMANDS">).  In this state, any changes (such
as deleting a message) should be committed.  Note that this state
can be skipped if the client disconnects without entering the
QUIT command, in which case any changes should be rolled back
during the DISCONNECT state.

After the client has disconnected, the server moves into the
DISCONNECT state and calls C<$obj-E<gt>disconnect()>, which you
may implement.  This state can be entered either from the
UPDATE state, or directly from the AUTHENTICATION or TRANSACTION
states.  In this state, any changes that were not previously
committed should be rolled back.

=head1 COMMANDS

Each line read from the user is split into two parts at the
first group of whitespace encountered.  The first part is
the command name, and the possible second part is the
parameter to the command.  Any case is accepted in the
command names, though the parameters to the commands may be
case sensitive.

Before a command is dispatched, it is checked against a list
of allowed commands.  If the command is not in this list, an
error is returned to the client and the command is not
dispatched.  This is for security reasons, as the command
supplied by the user is used directly to dispatch the
command.

A command is dispatched by looking for the similarly named
(but lower case) method of the object.  For example, when
dispatching the USER command, the method called is
C<$obj-E<gt>user()>.

The QUIT command is already implemented by this package.  It
changes the state to UPDATE, calls C<$obj-E<gt>commit(@_)>,
and then flags the client's connection to be closed by
calling C<$obj-E<gt>close_client()>.  In almost all cases,
this implementation of QUIT should be sufficient.

=head1 CAVEATS

=over 4

=item *

There are some issues with L<Net::Server::Fork|Net::Server::Fork>
on Win32.  The tests for L<Net::Server|Net::Server> are not
designed to work under Win32, though L<Net::Server|Net::Server>
itself does.  You should be able to skip the tests and it should
work.  However, see the next caveat.

=item *

If you are on Win32 and you don't specify the C<nonFork> import
option to use the non-forking personality of
L<Net::Server|Net::Server>, this module requires perl 5.8.  This
is because of a bug in the fork emulation of perl 5.6.1 that
causes perl to crash when forking is used in conjunction with
sockets.

=item *

I have had some issues with the forking personality of this
module causing my programs to leak memory on Win32.  I believe
this has something to do with the way C<fork> is emulated on
Win32 using threads, but I have not looked into it exhaustively.

I recommend you test the forking personality for memory leaks
before deploying your program, and you may need to fall back to
the nonforking personality.

=back

=head1 SEE ALSO

  L<Net::Server>, L<IO::Select>, L<Carp>

=head1 AUTHOR

Copyright (C) 2004, Cory Johns.  All rights reserved.

This module is free software; you can redistribute and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to:
Cory Johns E<lt>L<johnsca@cpan.org>E<gt>

=cut

