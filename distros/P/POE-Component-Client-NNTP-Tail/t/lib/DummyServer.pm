# Adapted from synopsis of PoCo::Server::NNTP
package DummyServer;

use strict;
use warnings;
use Carp::POE qw/croak/;
use Email::Simple;
use Email::Date::Format qw/email_date/;
use POE qw(Component::Server::NNTP);

# Our quick-n-dirty NNTP database :-)
# This is a HoA with keys being group names and value an array ref of msg-ids
my %Groups;
# This is a hash with msg-id keys and values containing articles
my %Messages;
# This is a hash with msg-id keys and values containing headers
my %Headers;

# A quick & dirty template to generate messages

#--------------------------------------------------------------------------#
# Methods
#--------------------------------------------------------------------------#

sub spawn {
  my ($class, %args) = @_;
  croak "port argument required" unless $args{port};
  
  my $self = bless \%args, $class; 
  $self->{session_id} = POE::Session->create(
    heap => $self,
    args => $self,
    package_states => [ 
      $class => [ qw(
        _start
        shutdown
        nntpd_listener_failed
        nntpd_connection
        nntpd_disconnected
        nntpd_cmd_post
        nntpd_cmd_ihave
        nntpd_cmd_slave
        nntpd_cmd_newnews
        nntpd_cmd_newgroups
        nntpd_cmd_list
        nntpd_cmd_group
        nntpd_cmd_article
        nntpd_cmd_head
      ) ]
    ],
    options => { trace => 0 },
  );
  return $self;
}

my $msg_count = 1;
sub add_article {
  my ($self, $group, $text) = @_;
  my $article = Email::Simple->new($text);

  # ensure we have a message id, date and subject
  my $id = "<$msg_count\@example.com>";
  $msg_count++;
  my $date = $article->header('Date') || email_date(time);
  my $from = $article->header('From') || 'anonymous@example.com';
  my $subject = $article->header('Subject') || "";

  # set required headers
  $article->header_set('Newsgroups', $group);
  $article->header_set('Path', $group);
  $article->header_set('Message-ID', $id);
  $article->header_set('Date', $date);
  $article->header_set('Subject', $subject);
  $article->header_set('From', $from);

  # store article
  my $crlf = $article->crlf;
  $Messages{$id} =  $article->as_string;
  $Headers{$id} = $article->header_obj->as_string;

  push @{$Groups{lc $group}}, $id;
  return;
}

sub _debug {
  my $where = (caller(1))[3];
  $where =~ s{.*::}{DS::};
  my @args = @_[ARG0 .. $#_];
  for ( @args ) { 
    $_ = 'undef' if not defined $_;
  }
  my $args = @args ? join( " " => "", (map { "'$_'" } @args), "" ) : ""; 
  warn "$where->($args)\n";
  return;
}

#--------------------------------------------------------------------------#
# Event handlers
#--------------------------------------------------------------------------#

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  &_debug if $heap->{Debug};
  print "# starting DummyServer on port $heap->{port}\n";
  $heap->{nntpd} = POE::Component::Server::NNTP->spawn( 
      alias   => 'nntpd', 
      posting => 0, 
      port    => $heap->{port},
  );
  $heap->{nntpd_id} = $heap->{nntpd}->session_id;
  $heap->{clients} = { };
  $kernel->alias_set( 'DummyServer' );
  return;
}

sub shutdown {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  &_debug if $heap->{Debug};
  $kernel->call( $heap->{nntpd_id}, 'unregister', 'all' );
  $heap->{nntpd}->shutdown;
  delete $heap->{nntpd};
  $kernel->alias_remove( $_ ) for $kernel->alias_list( $_[SESSION] );
  return;
}

sub nntpd_listener_failed {
  my ($kernel,$heap,$op,$numeric,$string) = @_[KERNEL,HEAP,ARG0,ARG1,ARG2];
  &_debug if $heap->{Debug};
  print "# Couldn't open socket: $op : $string\n";
  return;
}

sub nntpd_connection {
  my ($kernel,$heap,$sender,$client_id) = @_[KERNEL,HEAP,SENDER,ARG0];
  &_debug if $heap->{Debug};
  $heap->{clients}->{ $client_id } = { };
  return;
}

sub nntpd_disconnected {
  my ($kernel,$heap,$sender,$client_id) = @_[KERNEL,HEAP,SENDER,ARG0];
  &_debug if $heap->{Debug};
  delete $heap->{clients}->{ $client_id };
  return;
}

sub nntpd_cmd_slave {
  my ($kernel,$heap,$sender,$client_id) = @_[KERNEL,HEAP,SENDER,ARG0];
  &_debug if $heap->{Debug};
  $kernel->post( $sender, 'send_to_client', $client_id, '202 slave status noted' );
  return;
}

sub nntpd_cmd_post {
  my ($kernel,$heap,$sender,$client_id) = @_[KERNEL,HEAP,SENDER,ARG0];
  &_debug if $heap->{Debug};
  $kernel->post( $sender, 'send_to_client', $client_id, '440 posting not allowed' );
  return;
}

sub nntpd_cmd_ihave {
  my ($kernel,$heap,$sender,$client_id) = @_[KERNEL,HEAP,SENDER,ARG0];
  &_debug if $heap->{Debug};
  $kernel->post( $sender, 'send_to_client', $client_id, '435 article not wanted' );
  return;
}

sub nntpd_cmd_newnews {
  my ($kernel,$heap,$sender,$client_id) = @_[KERNEL,HEAP,SENDER,ARG0];
  &_debug if $heap->{Debug};
  $kernel->post( $sender, 'send_to_client', $client_id, '230 list of new articles follows' );
  $kernel->post( $sender, 'send_to_client', $client_id, '.' );
  return;
}

sub nntpd_cmd_newgroups {
  my ($kernel,$heap,$sender,$client_id) = @_[KERNEL,HEAP,SENDER,ARG0];
  &_debug if $heap->{Debug};
  $kernel->post( $sender, 'send_to_client', $client_id, '231 list of new newsgroups follows' );
  $kernel->post( $sender, 'send_to_client', $client_id, '.' );
  return;
}

sub nntpd_cmd_list {
  my ($kernel,$heap,$sender,$client_id) = @_[KERNEL,HEAP,SENDER,ARG0];
  &_debug if $heap->{Debug};
  $kernel->post( $sender, 'send_to_client', $client_id, '215 list of newsgroups follows' );
  foreach my $group ( keys %Groups ) {
    my $reply = join ' ', $group, scalar @{ $Groups{$group} } + 1, 1, 'n';
    $kernel->post( $sender, 'send_to_client', $client_id, $reply );
  }
  $kernel->post( $sender, 'send_to_client', $client_id, '.' );
  return;
}

sub nntpd_cmd_group {
  my ($kernel,$heap,$sender,$client_id,$group) 
    = @_[KERNEL,HEAP,SENDER,ARG0,ARG1];
  &_debug if $heap->{Debug};
  $group = lc $group;
  unless ( $group && exists $Groups{$group} ) { 
     $kernel->post( $sender, 'send_to_client', $client_id, '411 no such news group' );
     return;
  }
  my $last = scalar @{$Groups{$group}};
  $kernel->post( $sender, 'send_to_client', $client_id, "211 $last 1 $last $group group selected" );
  $_[HEAP]->{clients}->{ $client_id } = { group => $group };
  return;
}

sub nntpd_cmd_article {
  my ($kernel,$heap,$sender,$client_id,$article) 
    = @_[KERNEL,HEAP,SENDER,ARG0,ARG1];
  &_debug if $heap->{Debug};
  my $group = $_[HEAP]->{clients}{$client_id}{group};

  my ($msg_id, $set_current) = _validate_article_id(@_, $group);

  if ($msg_id) { # article exists
    $_[HEAP]->{clients}{$client_id}{current} = $article if $set_current;

    $kernel->post( $sender, 'send_to_client', $client_id, "220 $article $msg_id article retrieved - head and body follow" );
    $kernel->post( $sender, 'send_to_client', $client_id, $Messages{$msg_id});
    $kernel->post( $sender, 'send_to_client', $client_id, '.' );
  }

  return;
}

sub nntpd_cmd_head {
  my ($kernel,$heap,$sender,$client_id,$article) 
    = @_[KERNEL,HEAP,SENDER,ARG0,ARG1];
  &_debug if $heap->{Debug};
  my $group = $_[HEAP]->{clients}{$client_id}{group};

  my ($msg_id, $set_current) = _validate_article_id(@_, $group);

  if ($msg_id) { # article exists
    $_[HEAP]->{clients}{$client_id}{current} = $article if $set_current;

    $kernel->post( $sender, 'send_to_client', $client_id, "221 $article $msg_id article retrieved - head follows" );
    $kernel->post( $sender, 'send_to_client', $client_id, $Headers{$msg_id});
    $kernel->post( $sender, 'send_to_client', $client_id, '.' );
  }

  return;
}

sub _validate_article_id {
  my ($kernel,$heap,$sender,$client_id,$article, $group) 
    = @_[KERNEL,HEAP,SENDER,ARG0,ARG1,ARG2];
  &_debug if $heap->{Debug};

  $article = 1 unless $article;
  # ARTICLE <msg_id>
  if ( $article =~ /^<.*>$/ ) {
    if ( !defined $Messages{$article} ) {
     $kernel->post( $sender, 'send_to_client', $client_id, '430 no such article found' );
     return;
    }
    else {
      return $article;
    }
  }
  # ARTICLE [nnn]
  elsif ( $article =~ /^\d+$/ ) {
    if ( !defined $group ) {
      $kernel->post( $sender, 'send_to_client', $client_id, '412 no newsgroup selected' );
      return;
    }
    else {
      my $last = scalar @{$Groups{$group}} + 1;
      if ( $article < 1 || $article > $last ) {
        $kernel->post( $sender, 'send_to_client', $client_id, '423 no such article number' );
        return;
      }
      else {
        return ($Groups{$group}[$article-1], 1);
      }
    }
  }
  # default fallthrough
  $kernel->post( $sender, 'send_to_client', $client_id, '423 no such article number' );
  return;
}

1;
