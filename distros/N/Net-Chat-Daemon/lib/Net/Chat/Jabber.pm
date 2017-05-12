package Net::Chat::Jabber;

=head1 NAME

Net::Chat::Jabber - Jabber protocol adapter for Net::Chat::Daemon

=head1 API

=over 4

=cut

use Net::Jabber qw(Client);
our $VERSION = '0.1';
our @ISA = qw(Net::Jabber::Client);

use Net::Jabber::JID;
use Time::HiRes;

use strict;
use warnings;

# my $DEFAULT_SERVER = "jabber.org";
my $DEFAULT_SERVER = undef; # Have not gotten permission from jabber.org
my $DEFAULT_PASSWORD = "nopassword";
my $DEFAULT_RESOURCE = "default";

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

=item B<new>()

 class - the name of the class we're creating

 jid - a string giving the JID, or a JID object

 %options

   password - the password to provide during authentication. TODO: if
   this is not provided but a password is needed, some sort of
   authCallback is needed.

   loglevel - logs with level higher than this are not displayed.
   Defaults to 0.

=cut

sub new {
  my ($class, $app, $jid, %options) = @_;
  $jid = __default_jid($jid, $DEFAULT_SERVER, $DEFAULT_RESOURCE);

  my $self = $class->SUPER::new();
  @$self{keys %options} = values %options;

  $self->{jid} = $jid;
  $self->{password} ||= $DEFAULT_PASSWORD;
  $self->{user} ||= $jid->GetUserID;
  $self->{server} ||= $jid->GetServer;
  $self->{resource} ||= $jid->GetResource();

  $self->_log("[$self->{user}] pid=$$");

  $self->_init_callbacks($app);

  return $self;
}

sub __default_jid {
    my ($jid, $server, $resource) = @_;
    $jid = new Net::Jabber::JID($jid);
    $jid->SetServer($server) if defined($server) && ! $jid->GetServer;
    $jid->SetResource($resource) if defined($resource) && ! $jid->GetResource;
    return $jid;
}

=item B<connect>()

Connect to the server, attempting to register if the specified user is
not yet registered.

=cut

sub connect {
  my ($self) = @_;

  $self->Connect(hostname => $self->{server}) or return;

  my @identification = (username => $self->{user},
                        password => $self->{password},
                        resource => $self->{resource});
  my @result = $self->AuthSend(@identification);
  $self->_log(0, "auth status for $self->{user} ($$): $result[0] - $result[1]");

  if ($result[0] eq "401") {
    @result = $self->RegisterSend(@identification);
    $self->_log(0, "register status: " . join(" - ", @result));

    if ($result[0] eq "ok") {
        @result = $self->AuthSend(@identification);
        $self->_log(0, "auth status for $self->{user} ($$): $result[0] - $result[1]");
    }
  }

  $self->PresenceSend();
  return 1;
}

=item B<reconnect>()

Reestablish a broken connection.

=cut

sub reconnect {
    my ($self) = @_;
    $self->connect();
}

=item B<subscribe>($jid)

Subscribe to messages coming from $jid.

=cut

sub subscribe {
  my ($self, $jid) = @_;
  $jid = __default_jid($jid, $self->{server});
  $self->Subscription(type => "subscribe", to => $jid->GetJID("full"));
}

# Internal routine to initialize callbacks. Converts Jabber-specific
# callbacks into a simplified set. Which would be useful, if I were to
# document what that supposedly simplified set is.
sub _init_callbacks {
  my ($self, $app) = @_;

  $self->SetMessageCallBacks(normal => sub {
      local $app->{message} = $_[1];
      $self->_onMessage($app, @_);
  });

  $self->SetMessageCallBacks(chat => sub {
      local $app->{message} = $_[1];
      $self->_onMessage($app, @_);
  });

  $self->SetPresenceCallBacks(available => sub {
      for my $cb (@{ $app->{callbacks}{available} }) {
        return if ($cb->(@_)); # First true value handles
      }
  });

  $self->SetPresenceCallBacks(unavailable => sub {
      for my $cb (@{ $app->{callbacks}{unavailable} }) {
        return if ($cb->(@_)); # First true value handles
      }
  });

  $self->SetMessageCallBacks(error => sub {
      for my $cb (@{ $app->{callbacks}{error} }) {
        return if ($cb->(@_)); # First true value handles
      }
      my $error = $_[1];
      my $from = $error->GetFrom();
      my $subject = $error->GetSubject();
      my $body = $error->GetBody();
      $self->_log(-1, "($$) unnoticed error from $from: ($subject) $body");
  });
}

=item B<post>($to,$message,options...)

Send the message text $message to $to. Available options:

 subject: set the subject of the message (rarely used)

 thread: mark the message as a reply in the given thread

 attachments: an array of attachments, where each attachment
 is either a chunk of text, or an XML tree.

=cut

sub post {
  my ($self, $to, $message, %options) = @_;
  $to = __default_jid($to, $self->{server});
  my $subject = $options{subject} || ref($self) . " message";
  my @args = ();
  push(@args, thread => $options{thread}) if defined $options{thread};
  my $thr = ($options{thread} ? " thr=$options{thread}" : "");
  $self->_log(1, "($self->{user} -> $to$thr) $message");

  my $msg = new Net::Jabber::Message;
  $msg->SetMessage(to => $to->GetJid("full"),
                   subject => $subject,
                   body => $message,
                   @args);

  my @attachments = @{ $options{attachments} || [] };
  if (@attachments > 0) {
    my $attaches_node = $msg->{TREE}->add_child("attachments"); # FIXME {TREE}
    foreach my $attachment (@attachments) {
      my $attach_node = $attaches_node->add_child("attachment");
      if (! ref $attachment) {
        $attach_node->add_child("type", 'data');
        $attach_node->add_child("data", $attachment);
      } else {
        while (my ($tag, $value) = each %$attachment) {
          $attach_node->add_child($tag, $value);
        }
      }
    }
  }

  $self->Send($msg);
}

=item B<send_request>(to,message,options...)

Send out a request, but do not wait for the reply.

=cut

sub send_request {
  my ($self, $to, $message, %options) = @_;
  $options{thread} ||= "tid-" . Time::HiRes::time();
  $options{subject} ||= ref($self) . " request";
  $self->_log(1, "($self->{user}) starting transaction with thread $options{thread}");
  $self->start_transaction($options{thread}, $options{onReply});
  $self->post($to, $message, %options);
}

=item B<request>(to,message,options...)

Make a synchronous request. Returns the body of the reply message.

=cut

sub request {
  my ($self, $to, $message, %options) = @_;
  my $thread = $options{thread} ||= "tid-" . Time::HiRes::time();
  my $reply;
  $options{onReply} = sub { $reply = shift; };
  $self->send_request($to, $message, %options);
  while (1) {
    defined $self->Process() or die "jabber network error";
    last if defined $reply;
  }

  return $reply->GetBody();
}

# Internal routine that gets called on every message, before it gets
# categorized as a request, reply, or whatever.
sub _onMessage {
  my ($self, $app, $sid, $message, %extra) = @_;

  $self->_log(1, "($$) got message from " . $message->GetFrom() . ": " . $message->GetBody());

  # First, check whether it has a thread id of the syntax used for
  # request/reply pairs
  my $thread = $message->GetThread();
  if (defined($thread) && $thread =~ /^tid-/) {
    $self->_log(2, "  found thread $thread");
    if (exists $self->{active}{$thread}) {
      $self->_log(2, "  ending current transaction");
      my $cb = $self->end_transaction($thread);
      if (UNIVERSAL::isa($cb, 'CODE')) {
        return $cb->($message, $thread, %extra);
      } else {
        return $app->onReply($message, $thread, %extra);
      }
    } else {
      $self->_log(2, "  no current transaction, must be request");
      return $app->onRequest($message, %extra);
    }
  } else {
    $self->_log(2, "  no thread");
    return $app->onMessage($message, %extra);
  }
}

=item B<start_transaction>($transaction_id, $onReply)

Start a transaction. A transaction is identified by the given id,
and... blah blah blah this is very important but I don't remember
what I did here.

=cut

sub start_transaction {
  my ($self, $trans_id, $onReply) = @_;
  $onReply ||= 1;
  $self->{active}{$trans_id} = $onReply;
}

=item B<end_transaction>($transaction_id)

Normally called automatically. Terminates a transaction and erases
the transaction callback.

=cut

sub end_transaction {
  my ($self, $trans_id) = @_;
  if (exists $self->{active}{$trans_id}) {
    my $cb = delete $self->{active}{$trans_id};
    $self->remove_callback('message', $trans_id);
    return $cb;
  } else {
    $self->_log(-1, "tried to end nonexistent transaction '$trans_id'");
    return;
  }
}

=item B<count_transactions>($transaction_id)

Return the number of active karfloomer hangers for the given
transaction. The method name is awful; this is counting karfloomer
hangers for a given transaction, not the number of transactions. FIXME
when I figure this all out.

=cut

sub count_transactions {
  my ($self) = @_;
  return scalar(keys %{ $self->{active} });
}

=item B<barrier>()

Wait until no more active transactions are outstanding.

=cut

sub barrier {
  my ($self) = @_;

  $self->_log(1, "[$self->{user}] ...pausing...");
  while (1) {
    my $nactive = $self->count_transactions();
    last if $nactive == 0;
    $self->_log(0, "[$self->{user}] ...pausing, $nactive active trans");
    last if ! defined $self->Process(5);
  }
}

=item B<poll>()

Check whether any messages are available.

=cut

sub poll {
  my ($self) = @_;
  $self->Process(0);
}

=item B<wait>([$timeout])

Wait $timeout seconds for more messages to come in. If $timeout is not
given or undefined, block until a message is received.

Return value: 1 = data received, 0 = ok but no data received, undef = error

=cut

sub wait {
  my $self = shift;
  $self->Process(@_);
}

1;

=back

=head1 SEE ALSO

Net::Chat::Daemon, Net::Jabber, Net::XMPP

=head1 AUTHOR

Steve Fink E<lt>sfink@cpan.orgE<gt>

Send bug reports directly to me. Include the module name in the
subject of the email message.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Steve Fink

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
