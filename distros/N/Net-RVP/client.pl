#!/hildev/bin/perl -w

# dbr 200031118
# client

package main;

use strict;

use Event;

use Net::RVP;
use Net::RVP::Server;
use IO::Socket::INET;
use Event::IO::Server;

use IO::File;
use Errno qw(:POSIX);
use Fcntl;

use Config::General;
use constant CONFIG_FILE => 'client.conf';


# ---RVP sink---
package sink;
use base qw(Net::RVP::Sink);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{sindex} = 0;
  $self->{lists} = $self->{slist} = {};
  return $self;
}

sub find_session {
  my ($self,$sess) = @_;
  if(not ref $sess) {
    return $self->{lists}->{$sess};
  }
  my $id = $self->{slist}->{$sess->id()};
  unless($id) {
    $id = $self->{slist}->{$sess->id()} = ++$self->{sindex};
    $self->{lists}->{$self->{sindex}} = $sess;
  }
  return $id;
}

sub open_event {
  my ($self,$sess) = @_;
  $self->find_session($sess);
}

sub close_event {
  my ($self,$sess) = @_;
  my $id = $self->find_session($sess);
  delete $self->{slist}->{$id};
  delete $self->{lists}->{$sess->id()};
}

sub join_event {
  my ($self,$user,$sess) = @_;
  my $id = $self->find_session($sess);
  print "<$id:".$user->display()." has joined>\n";
  $main::Log->print("<$id:".$user->display()." has joined>\n");
  return $self->SUPER::join_event(@_);
}

sub part_event {
  my ($self,$user,$sess) = @_;
  my $id = $self->find_session($sess);
  print "<$id:".$user->display()." has left>\n";
  $main::Log->print("<$id:".$user->display()." has left>\n");
  return $self->SUPER::part_event(@_);
}

sub typing_event {
  my ($self,$user,$sess) = @_;
  my $id = $self->find_session($sess);
#  print "<$id:".$user->display()." is typing>\n";  # XXX annoying
  return $self->SUPER::typing_event(@_);
}

sub message_event {
  my ($self,$user,$sess,$text) = @_;
  my $id = $self->find_session($sess);
  print "<$id:".$user->display()."> $text\n";
  $main::Log->print("<$id:".$user->display()."> $text\n");

=pod
  # Eliza code
  require Chatbot::Eliza;
  $sess->{bot} ||= Chatbot::Eliza->new();
  my $reply = $sess->{bot}->transform($text);
  print "> $reply\n";
  $main::Log->print("> $reply\n");
  $sess->typing();
  Event->timer(after => 2+rand(5), cb => sub { $sess->say($reply) });
=cut

  return $self->SUPER::message_event(@_);
}

sub change_event {
  my ($self,$user,$prop) = @_;
  my $now = sprintf "%02d:%02d:%02d ", (localtime)[2,1,0];
  while(my ($k,$v) = each %$prop) {
    print $now.$user->display().": $k => $v\n";
    $main::Log->print($user->display().": $k => $v\n");
  }
}


# ---main---

package main;


# ---globals---

my $sink = sink->new();
my $rvp;
our ($Log,$Debug);


# ---subs---

# read config
my $Config;
sub read_config {
  print "reading '".CONFIG_FILE."'\n";
  my $obj = Config::General->new(-file => CONFIG_FILE,
   -AllowMultiOptions => 1, -UseApacheInclude => 1, -AutoTrue => 1);
  return { $obj->getall() };
}


# write config
sub write_config {
  print "writing '".CONFIG_FILE."'\n";
  my $config = shift;
  my $obj = Config::General->new();
  $obj->save(CONFIG_FILE,%{$config});
}


# line event on stdin
sub stdin_line_event {
  my $line = shift;
  if($line =~ /^q(uit)?\b/i) {
    Event::unloop();

  } elsif($line =~ /^o(?:pen)?\s+(.*)$/i) {
    my $name = $1;
    my $sess = $rvp->session();
    my $id = $sink->find_session($sess);
    print "<$id: created>\n";
    $Log->print("<$id: created>\n");
    if(my $user = $rvp->user($name)) {
      $sess->add($user);
      print "<$id:".$user->display()." added>\n";
      $Log->print("<$id:".$user->display()." added>\n");
    } else {
      print "can't find user '$name'\n";
    }

  } elsif($line =~ /^(\d+)\s+a(?:dd)?\s+(.*)$/i) {
    my ($id,$name) = ($1,$2);
    if(my $sess = $sink->find_session($id)) {
      if(my $user = $rvp->user($name)) {
        $sess->add($user);
        print "<$id:".$user->display()." added>\n";
        $Log->print("<$id:".$user->display()." added>\n");
      } else {
        print "can't find user '$name'\n";
      }
    } else {
      print "can't find session '$sess'\n";
    }

  } elsif($line =~ /^c(?:lose)?\s+(\d+)$/i) {
    my $id = $1;
    if(my $sess = $sink->find_session($id)) {
      $sess->leave();
      print "<$id: leaving>\n";
      $Log->print("<$id: leaving>\n");
    } else {
      print "can't find session $1\n";
    }

  } elsif($line =~ /^\.\s*(\d+)\s*(.*)$/) {
    my ($id,$text) = ($1,$2);
    if(my $sess = $sink->find_session($id)) {
      $sess->say($text);
      $Log->print("<$id:".($rvp->self()->display())."> $text\n");
    } else {
      print "can't find session $1\n";
    }

  } else {
    print "'$line' not understood\n";
  }
}


# read event on stdin (liberally borrowed from my Event::IO::Record)
my $Data = '';
use constant READ_SIZE => 1024;
sub stdin_read_event {
  my $e = shift;

  # buffer up input until we can't read any more
  my ($frag,$count) = ('',0);

  do {{
    # undef means we have an error so log it and close
    if(not defined read(STDIN,$frag,READ_SIZE) and $!) {
      last if EAGAIN == $! or EWOULDBLOCK == $!;   # no data available
      next if EINTR == $!;                         # interrupted by signal

      # queue up the read error until we've processed what we've read
      warn "read error: $!";
      last;
    }

    # assume if we got 0 bytes and no error that it's time to bail
    # if not, we get an infinite sequence of read_events....
    # don't bail until we've sent the lines that we have, however
    if(not length $frag and not $count) {
      print "EOF\n";
      Event::unloop();
      return;
    }

    # otherwise append to the existing block and read until we run out of data
    $Data .= $frag;
    $count .= length $frag;
  }} while length $frag == READ_SIZE;

  # send each line as an event
  while(length $Data and $Data =~ s/^(.*?)\n//s) {
    stdin_line_event($1);
  }
}


# ---top---

$| = 1;

# read configuration
my $config = read_config();

# create callback server (use port => 0 to select a port automatically)
print "creating callback server\n";
my %port = $config->{port} ? (LocalPort => $config->{port}) : ();
my $lsock = 
 IO::Socket::INET->new(%port, ReuseAddr => 1, Listen => 1);
die $! unless $lsock;
my $server = Event::IO::Server->new(handle => $lsock,
 spawn => 'Net::RVP::Server') or die 'failed to create server';
my $port = $lsock->sockport();
print "listening on port $port\n";

# start debug and chat logs
$Debug = IO::File->new('>>debug.log') or die $!;
$Log   = IO::File->new('>>chat.log')  or die $!;
$Debug->autoflush(1);
$Debug->print("logging in at ".(scalar localtime)."\n");

$Log->autoflush(1);
$Log->print("logging in at ".(scalar localtime)."\n");

print 'password:';
system('stty -echo');
chomp(my $pass = <STDIN>);
system('stty echo');

# create presentity object
$rvp = Net::RVP->new(
 debug => sub { $Debug->print(@_) },
# ideally we could get the IP using IO::Socket::INET::sockport(), but we
# can't do it for the server (it gives back 0.0.0.0 since it isn't connected),
# and since the client uses LWP::UserAgent, we can't get the IP in time to
# send it (unless we could hook in somewhere but that wouldn't be portable)
# so, for now our IP must be specified manually, here:
 host  => "1.2.3.4:$port",
 name  => 'First_Last',
 user  => 'domain\\login',
 pass  => $pass,
 site  => 'rvp.server.com:80',
 sink  => $sink,
);

# set callback
$server->data(sub { $rvp->notify(shift) });

# log in, set status to online, set primary subscription renewal event
print "logging in\n";
my $renew = $rvp->login() or die 'login failed';
$rvp->status('online');
Event->timer(interval => $renew-30, cb => sub { $rvp->renew() });

# subscribe to our contacts
print "adding contacts\n";
my $contacts = $config->{contact} || {};
$contacts = $contacts->{name} || [];
$contacts = [$contacts] unless ref $contacts;

my $start = time;
$renew = 0;
my $users = {};
for my $contact(@$contacts) {
  my $user = $rvp->user($contact);
  if(my $watch = $user->watch()) {
    $renew = $watch;
    print 'Adding watch for '.$user->display().' ('.$user->email()."); status ".
     $user->state()."\n";
    $users->{lc $user->name()} = $user;
  }
}
if($renew) {
  my $ival = $renew-(time-$start)-30;  # 30 seconds short of timing out
  Event->timer(interval => ($ival < 1 ? 1 : $ival), cb => sub {
   $_->watch() for values %$users; });
}

=pod
my @state = qw(offline online idle on-phone at-lunch busy);
Event->timer(interval => 60,
 cb => sub { $rvp->status($state[rand @state]) });
=cut

# add a STDIN I/O event
if(my $flags = fcntl(STDIN,F_GETFL,pack '') >= 0) {
  fcntl(STDIN,F_SETFL,$flags | O_NONBLOCK);
}
Event->io(fd => \*STDIN, poll => 'r', cb => \&stdin_read_event);

# start event loop; this is it...
print "ready\n\n";
Event::loop();

# on finish, set STDIN back to non-blocking and write out the configuration
if(my $flags = fcntl(STDIN,F_GETFL,pack '') >= 0) {
  fcntl(STDIN,F_SETFL,$flags & ~O_NONBLOCK);
}
$config->{contact}->{name} = [ map $_->name(), values %$users ];
write_config($config);
print "logging out\n";
$rvp->status('offline');
$rvp->logout();
$Net::RVP::Debug = 0;

$Log->print("logging out at ".(scalar localtime)."\n\n");
$Log->close();

$Debug->print("logging out at ".(scalar localtime)."\n\n");
$Debug->close();

undef $rvp;
