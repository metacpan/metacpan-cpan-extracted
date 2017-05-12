=head1 NAME

Net::Chat::Daemon - run a daemon that is controlled via instant messaging

=head1 ABSTRACT

This package is intended to serve as a superclass for objects that
want to communicate via IM messages within a distributed network of
client nodes and a coordinator, without dealing with the complexities
or implementation details of actually getting the messages from place
to place.

It pretends to be protocol-neutral, but for now and the conceivable
future will only work with a Jabber transport. (It directly uses the
message objects and things that Jabber returns.)

Note that this package will NOT help you implement an instant
messaging server. This package is for writing servers that communicate
with other entities via instant messages -- servers written using this
package are instant messaging *clients*.

=head1 SYNOPSIS

  package My::Server;
  use base 'Net::Chat::Daemon';
  sub handleHello {
    return "hello to you too";
  }
  sub handleSave {
    my ($filename, $file) = @_;
    return "denied" unless $filename =~ /^[.\w]+$/;
    open(my $fh, ">/var/repository/$filename") or return "failed: $!";
    print $fh $file;
    close $fh or return "failed: $!";
    return "ok";
  }
  sub someMethod {
    my ($self, @args) = @_;
    .
    .
    .
  }
  sub new {
    my ($class, $user, %options) = @_;
    return $class->SUPER::new(%options,
                              commands => { 'callMethod' => 'someMethod',
                                            'save' => \&handleSave });
  }

  package main;
  my $server = My::Server->new('myuserid@jabber.org');
  $server->process();

  # or to do it all in one step, and retry connections for 5 minutes
  # (300 seconds) before failing due to problems reaching the server:

  My::Server->run('myuserid@jabber.org', retry => 300);

When you run this, you should be able to send a message to
userid@jabber.org saying "hello" and get a response back, or
"callMethod a b c" to call the method with the given arguments. To use
the "save" command, you'll need to use a command-line client capable
of sending attachments in the format expected by this server (it
currently does not use any standard file-sending formats). The
C<jabber> command packaged with this module can do this via the C<-a>
command-line option.

A note on the implementation: when I first wrote this, it was really
only intended to be used with Jabber. The code hasn't been fully
restructured to remove this assumption.

=head2 WARNING

The Net::Chat::Daemon name is most likely temporary (as in, I don't
like it very much, but haven't come up with anything better.) So be
prepared to change the name if you upgrade.

=head1 API

=over 4

=cut

package Net::Chat::Daemon;
our $VERSION = "0.3";

use strict;
use Time::HiRes qw(time);
use Carp qw(croak);

# Subclasses. These probably ought to be discovered and loaded
# dynamically.
use Net::Chat::Jabber;
our %scheme_registry = ( 'jabber' => 'Net::Chat::Jabber',
                         'xmpp' => 'Net::Chat::Jabber',
                       );

# Internal routine to display a log message depending on the loglevel
# setting.
sub _log {
    my $self = shift;
    my $message;
    my $level = 0;
    if (@_ == 1) {
        $message = shift;
    } else {
        ($level, $message) = @_;
    }
    my $allow_level = $self->{loglevel} || 0;
    return if $level > $allow_level;
    print $message, "\n";
}

=item B<new>($user, %options)

To implement a server, you need to define a set of commands that it
will respond to. See C<getHandler>, below, for details on how commands
are registered. The part that's relevant to this method is that you
can pass in a C<commands> option, which is a hash ref mapping command
names to either subroutines or method names. When the server receives
a message, it will carve up the message into a command name and
whitespace-separated arguments. See C<onRequest>, below, for details.

Methods that are invoked by being values in the C<commands> hash will
also be given the usual $self parameter at the beginning of the
parameter list, of course.

The $user argument to the C<new>() method is something like
jabber://userid@jabber.org/someresource or just
userid@jabber.org/someresource (who are we kidding?) Theoretically,
this allows a future subclass to work with yahoo://userid, but don't
hold your breath.

=cut

sub new {
  my ($class, $user, %opts) = @_;
  my $scheme = 'jabber'; # Default
  ($scheme, $user) = ($1, $2) if $user =~ m!^(\w+)://(.*)!;

  my $cxn_opts = delete $opts{connection_options} || {};
  $cxn_opts->{password} ||= delete $opts{password};
  my $self = bless { %opts, user => $user }, $class;

  my $cxn_class = $scheme_registry{$scheme}
    or croak "unknown scheme '$scheme'";

  $self->{cxn} = $cxn_class->new($self, $user, %$cxn_opts);

  if (defined $opts{master}) {
    $self->push_callback('unavailable', sub { $self->checkMaster(@_) });
    $self->subscribe($opts{master});
  }

  $self->{cxn}->connect()
    or die "unable to connect to server for $user";

  return $self;
}

=item B<run>($user, %options)

Create a daemon with the given options, and loop forever waiting for
messages to come in. If the IM system dies, exit out with an error
unless the 'retry' option is given, in which case it will be
interpreted as the maximum number of seconds to retry, or zero to
retry forever (this is often a good idea.)

If you want your server to exit gracefully, define your own command
that calls C<exit(0)>.

=cut

sub run {
  my ($class, $user, %opts) = @_;
  my $RETRY_GAP = 1.5; # Seconds between retries

  my $server = $class->new($user, %opts);

  my $retry_sec = $opts{retry} or do {
      1 while defined $server->process();
      exit 1;
  };

  # We know we want to retry now.
  MAINLOOP: while (1) {
      1 while defined $server->process();
      next if $retry_sec == 0; # Retry forever

      if ($retry_sec == 0) {
          # Retry forever
          sleep $RETRY_GAP;
      } elsif ($retry_sec < $RETRY_GAP) {
          my $retry_deadline = time() + $retry_sec;
          do {
              sleep $RETRY_GAP;
              next MAINLOOP if defined $server->process();
          } while (time() < $retry_deadline);
          last; # Couldn't process anything successfully before deadline
      }
  }

  exit 1;
}

=item B<push_callback>($type, $callback, [$id])

=item B<unshift_callback>($type, $callback, [$id])

=item B<remove_callback>($type, $id)

Add or remove callback for the event $type. C<remove_callback()> is
only useful if an $id was passed into C<push_callback> or
C<unshift_callback>.

Valid types:
  message
  available
  unavailable
  error

=cut

sub push_callback {
  my ($self, $type, $callback, $id) = @_;
  push @{ $self->{callbacks}{$type} }, $callback;
  if (defined $id) {
    $self->{callback_id}{$id} = $self->{callbacks}{$type}->[-1];
  }
}

sub unshift_callback {
  my ($self, $type, $callback, $id) = @_;
  unshift @{ $self->{callbacks}{$type} }, $callback;
  if (defined $id) {
    $self->{callback_id}{$id} = $self->{callbacks}{$type}->[-1];
  }
}

sub remove_callback {
  my ($self, $type, $id) = @_;
  my $cb = $self->{callback_id}{$id};
  if (defined $cb) {
    delete $self->{callback_id}{$id};
    my $cb_list = $self->{callbacks}{$type};
    @$cb_list = grep { $_ != $cb } @$cb_list;
  }
}

=item B<onMessage>($msg, %extra)

This method will be invoked as a callback whenever a regular chat
message is received. The default implementation is to relay the
message to C<onRequest>, but this may be overridden in a subclass to
distinguish between the two.

=cut

sub onMessage {
  my ($self, $msg, %extra) = @_;
  $self->onRequest($msg, %extra);
}

=item B<onReply>($msg, %extra)

This method will be invoked as a callback whenever a chat message is
received in reply to a previous request. The default implementation is
to relay the message to C<onMessage> above, but this may be overridden
in a subclass to distinguish between the two.

=cut

sub onReply {
  my ($self, $message, $thread, %extra) = @_;
  $self->onMessage($message, %extra);
}

=item B<setCommand>($name, $command)

Set the callback associated with a command. If a string is passed in,
it will be treated as a method on the current object (the object that
C<setCommand> was called on). The arguments to the method will be the
words in the command string. If a closure is passed in, it will be
invoked directly with the words in the command string. The $self
object will not be passed in by default in this case, but it is easy
enough to define your command like

  $x->setCommand('doit' => sub { $x->doit(@_) })

Note that all commands are normally set up when constructing the
server, but this method can be useful for dynamically adding new
commands. I use this at time to temporarily define commands within
some sort of transaction.

=cut

sub setCommand {
  my ($self, $name, $command) = @_;
  $self->{commands}{$name} = $command;
}

=item B<getHandler>($name)

Get the handler for a given command. The normal way to do this is to
pass in a 'commands' hash while constructing the object, where each
command is mapped to the name of the corresponding method.

Alternatively, you can simply define a method named handleSomething,
which will set the command 'something' (initial letter lower-cased) to
call the handleSomething method. (So 'handleSomeThing' would create
the command 'someThing'.)

Also, if you ask for help on a command, it will call the method
'helpXxx' where 'xxx' is the name of the command. If no such method
exists, the default response will be "(command) args..." (accurate but
hardly helpful).

=cut

sub getHandler {
  my ($self, $name) = @_;
  my $sub;
  if ($name eq 'help') {
    $sub = sub { $self->showHelp(@_) };
  } else {
    $sub = $self->{commands}{$name};
  }

  $sub ||= $self->can("handle\u$name");

  return $sub;
}

=item B<showHelp>([$command])

Return a help message listing out all available commands, or detailed
help on the one command passed in.

=cut

sub showHelp {
  my ($self, $command) = @_;

  if (defined($command)) {
    return $self->{help}{$command} if defined $self->{help}{$command};
    my $sub = $self->can("help\u$command");
    return $sub->($self) if $sub;
    return "$command args..."; # Wise-ass help
  }

  my %commands;
  @commands{keys %{ $self->{commands} }} = ();

  no strict 'refs';
  foreach (map { s/handle//; "\l$_" }
           grep { *{${ref($self)."::"}{$_}}{CODE} }
           grep { /^handle/ }
           keys %{ref($self)."::"})
  {
    $commands{$_} = 1;
  }

  return "Available commands: " . join(" ", sort keys %commands);
}

=item B<onRequest>($msg, %extra)

This method will be invoked as a callback whenever a request is
received. As you know if you've read the documentation for
C<onMessage> and C<onReply>, by default all messages go through this
handler.

The default implementation of onRequest parses the message into a
command and an array of arguments, looks up the appropriate handler
for that command, invokes the handler with the arguments, then sends
back a reply message with the return value of the handler as its text.

If any files are attached to the message, they are extracted and
appended to the end of the argument list.

An example: if you send the message "register me@jabber.org ALL" to
the server, it will look up its internal command map. If you defined a
C<handleRegister> method, it will call that. Otherwise, if you
specified the command 'register' in the commands hash, it will call
whatever value if finds there. Two arguments will be passed to the
handler: the string "me@jabber.org", and the string "ALL".

=cut

sub onRequest {
  my ($self, $message) = @_;
  my $body = $message->GetBody();
  my $from = $message->GetFrom();
  $self->_log(1, "[$self->{user}] from($from): $body\n");

  # Parse the request body into a command and a list of arguments
  my ($cmd, @args) = $body =~ /('(?:\\.|.)*'|"(?:\\.|.)*"|\S+)/g;
  foreach (@args) {
    $_ = substr($_, 1, -1) if (/^['"]/);
  }

  # Add the attachments to the end of the @args array. This is most
  # likely an abuse of the Jabber protocol.
  my $attachments_node = $message->{TREE}->XPath("attachments");
  my @attachments = $attachments_node ? $attachments_node->children() : ();
  foreach my $node (@attachments) {
    my %attachment;
    foreach ($node->children()) {
      $attachment{$_->get_tag()} = $_->get_cdata();
    }
    push @args, \%attachment;
  }

  # Lookup the handler for this command and call it, then send back
  # the result as a reply.
  my $meth = $self->getHandler($cmd);
  my $reply = $message->Reply();
  local $self->{last_message} = $message;
  if ($meth) {
    if (UNIVERSAL::isa($meth, 'CODE')) {
      $reply->SetBody($meth->(@args));
    } else {
      $reply->SetBody($self->$meth(@args));
    }
    $self->{cxn}->Send($reply);
    return 1;
  } else {
    $self->_log(0, "[$self->{user}] ignoring message: $body");
    return;
  }
}

=item B<checkMaster>($sid, $presence)

Internal: presence unavailable callback - exit if the master exited

=cut

sub checkMaster {
  my ($self, $sid, $presence) = @_;
  if ($self->{master} eq $presence->GetFrom("jid")->GetUserID()) {
    $self->_log(0, "[$self->{user}] master terminated, exiting.");
    exit 0;
  }
  return;
}

=item B<process>([$timeout])

Wait $timeout seconds for more messages to come in. If $timeout is not
given or undefined, block until a message is received.

Return value: 1 = data received, 0 = ok but no data received, undef = error

=cut

sub process {
  my $self = shift;
  return $self->{cxn}->wait(@_);
}

################## SYNCHRONIZATION METHODS #####################

sub _makeId {
  return time();
}

=item B<waitUntilAllHere>($nodes)

This method is used for things like test harnesses, where you might
want to wait until a set of nodes are all alive and active before
starting the test case. You pass in a list of users, and this method
will wait until all of them have logged into the server.

Implementation: wait until receiving presence notifications from the
given list of nodes. Works by temporarily adding new presence
callbacks, and periodically pinging nodes that haven't come up yet.

Arguments: $nodes - reference to an array of user descriptors (eg jids)

I suppose I ought to add a timeout argument, but right now, this will
block until all nodes have reported in.

=cut

sub waitUntilAllHere {
  my ($self, $nodes) = @_;

  my ($id1, $id2, $id3) = (_makeId(), _makeId(), _makeId());
  $self->unshift_callback(available => sub { $self->onSyncLogin(@_) }, $id1);
  $self->unshift_callback(unavailable => sub { $self->onSyncLogout(@_) }, $id2);
  $self->unshift_callback(error => sub { $self->onSyncError(@_) }, $id3);

  # Maximum time to pause before asking someone if they're awake yet.
  my $PATIENCE = 0.5; # Seconds

  $self->{allhere} = (@$nodes == 0);

  # Ignore any nodes that we don't care about
  delete $self->{care_about};
  $self->{care_about}{$_} = 1 foreach (@$nodes);

  # Initialize the set of nodes that we're waiting for. This is
  # different from the set of nodes we care about, in that a node
  # could disappear and come back a few times while we're waiting for
  # everyone to arrive.
  delete $self->{waiting};
  $self->{waiting}{$_} = 1 foreach (@$nodes);

  # Keep a timestamp for the last time we've heard from each of the
  # nodes. This is used to decide when to send another ping.
  my $now = time();
  delete $self->{lastcheck};
  $self->{lastcheck}{$_} = $now foreach (@$nodes);

  while (! $self->{allhere}) {
    my ($oldest, $delay);
    ($oldest) =
      sort { $self->{lastcheck}{$a} <=> $self->{lastcheck}{$b} }
        keys %{ $self->{waiting} };
    my $age = time() - $self->{lastcheck}{$oldest};
    $delay = $PATIENCE - $age;
    $delay = 0 if $delay < 0;

    # Wait for $delay seconds for any responses
    $self->process($delay);

    last if $self->{allhere};

    # Ping oldest
    $self->subscribe("$oldest\@$self->{server}");
    $self->{lastcheck}{$oldest} = time();
  }

  # Everyone is here, so remove our callbacks
  $self->remove_callback('available', $id1);
  $self->remove_callback('unavailable', $id2);
  $self->remove_callback('error', $id3);

  foreach my $node (@$nodes) {
    $self->post($node, "hey guys", subject => "allhere");
  }
}

=item B<onSyncLogin>($sid, $presence)

Callback used when synchronizing with a bunch of nodes. Notified
when someone logs in who we care about.

=cut

sub onSyncLogin {
  my ($self, $sid, $presence) = @_;
  my $status = $presence->GetStatus();
  my $show = $presence->GetShow();
  my $from = $presence->GetFrom();
  my $node = $presence->GetFrom("jid")->GetUserID();
  $self->_log(1, "($$) presence from $node: $status ($show)");
  if ($self->{care_about}{$node} && $self->{waiting}{$node}) {
    delete $self->{waiting}{$node};
    if (0 == keys %{ $self->{waiting} }) {
      $self->{allhere} = 1;
    }
    return 1;
  }
  return;
}

=item B<onSyncLogout>($sid, $presence)

If a node disappears while we are waiting for everyone to gather,
then re-set its waiting flag.

=cut

sub onSyncLogout {
  my ($self, $sid, $presence) = @_;
  my $status = $presence->GetStatus();
  my $show = $presence->GetShow();
  my $from = $presence->GetFrom();
  my $node = $presence->GetFrom("jid")->GetUserID();
  $self->_log(1, "bye bye from $node: $status ($show)");
  if ($self->{care_about}{$node}) {
    $self->{waiting}{$node} = 1;
    return 1;
  }
  return;
}

=item B<onSyncError>($sid, $message)

Watch for 404 errors coming back while waiting for all nodes to be
present.

=cut

sub onSyncError {
  my ($self, $sid, $msg) = @_;
  my $code = $msg->GetErrorCode();
  return if $code != 404; # do not handle

  my $from = $msg->GetFrom();
  $self->_log(0, "[$self->{user}] client $from not found");
  my $node = $msg->GetFrom("jid")->GetUserID();
  $self->{lastcheck}{$node} = time();
  return 1;
}

1;

=back

=head1 SEE ALSO

Net::Chat::Jabber, Net::Jabber, Net::XMPP

=head1 AUTHOR

Steve Fink E<lt>sfink@cpan.orgE<gt>

Send bug reports directly to me. Include the module name in the
subject of the email message.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Steve Fink

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
