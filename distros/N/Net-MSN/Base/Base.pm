# Net::MSN::Base - Base class used by Net::MSN and Net::MSN::SB.
# Originally written by: 
#  Adam Swann - http://www.adamswann.com/library/2002/msn-perl/
# Modified by:
#  David Radunz - http://www.boxen.net/
#
# $Id: Base.pm,v 1.6 2003/07/09 16:51:50 david Exp $ 

package Net::MSN::Base;

use strict;
use warnings;

BEGIN {
  # Modules
  # CPAN
  use IO::Socket;
  use IO::Select;
  use Hash::Merge qw( merge );

  # Package specific
  use Net::MSN::Debug;

  use vars qw($VERSION);

  $VERSION = do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r }; 

  # construct global Select
  $__PACKAGE__::Select = IO::Select->new();

  # construct global Socks
  $__PACKAGE__::Socks = {};

  # Unique Transmission ID
  $__PACKAGE__::TrID = -1;
}

sub new {
  my ($class, %args) = @_;

  my $self = bless({
    'Version'           =>      $VERSION,
    'Debug'             =>      0,
    'Debug_Lvl'         =>      0,
    'Debug_Log'         =>      '',
    'Debug_STDERR'      =>      1,
    'Debug_STDOUT'	=>	0,
    'Debug_LogCaller'   =>      1,
    'Debug_LogTime'     =>      1,
    'Debug_LogLvl'      =>      1,
    '_L'                =>      '',
    '_Log'		=>	'',
    '_Type'		=>	'NS'
  }, ref($class) || $class);

  $self->set_options(\%args);
  $self->_new_Log_obj();

  return $self;
}

sub set_options {
  my ($self, $opts) = @_;

  my %opts = %$opts;
  foreach my $key (keys %opts) {
    if (ref $opts{$key} eq 'HASH') {
      $self->{$key} =
        \%{ merge($opts{$key}, $self->{$key}) };
    } else {
      $self->{$key} = $opts{$key};
    }
  }
}

sub _new_Log_obj {
  my ($self) = @_;

  return if ((defined $self->{_L} && $self->{_L}) ||
    (defined $self->{_Log} && $self->{_Log}));

  # Create a new Net::MSN::Debug object for debug
  $self->{_L} = new Net::MSN::Debug(
    'Debug'     =>  $self->{Debug},
    'Level'     =>  $self->{Debug_Lvl},
    'LogFile'   =>  $self->{Debug_Log},
    'STDERR'    =>  $self->{Debug_STDERR},
    'STDOUT'    =>  $self->{Debug_STDOUT},
    'LogCaller' =>  $self->{Debug_LogCaller},
    'LogTime'   =>  $self->{Debug_LogTime},
    'LogLevel'  =>  $self->{Debug_LogLvl}
  );

  die "Unable to create L obj!\n"
    unless (defined $self->{_L} && $self->{_L});

  $self->{_Log} = $self->{_L}->get_log_obj();

  die "Unable to create Log obj!\n"
    unless (defined ($self->{_Log} && $self->{_Log}));
}

sub merge_opts {
  my ($self, $defaults, $args) = @_;

  return unless ((defined $defaults && ref $defaults eq 'HASH') ||
    (defined $args && ref $args eq 'HASH'));

  my %opts = %$defaults;
  foreach my $key (keys %$args) {
    if (ref $args->{$key} eq 'HASH') {
      $opts{$key} =
        \%{ merge($args->{$key}, $defaults->{$key}) };
    } else {
      $opts{$key} = $args->{$key};
    }
  }

  return %opts;
}

sub construct_socket {
  my ($self) = @_;

  $self->{Socket} = $self->connect_socket(
    $self->{_Host}, $self->{_Port}
  );

  $__PACKAGE__::Select->add($self->{Socket});

  $__PACKAGE__::Socks->{$self->{Socket}->fileno} = \$self;
}

sub remove_socket {
  my ($self) = @_;

  if (defined $self->{Socket} && $self->{Socket}) {
    my $fn = $self->{Socket}->fileno;
    $__PACKAGE__::Select->remove($self->{Socket});
    delete($__PACKAGE__::Socks->{$fn})
      if (defined $fn && defined $__PACKAGE__::Socks->{$fn});

    if ($self->{_Type} eq 'SB') {
      $self->{_Log}('Disconnected from Switch Board: '. $self->{_Host}. ':'.
	$self->{_Port}. ' (Handle: '. $self->{Handle}. 
	', Socket: '. $fn. ')', 2);
    } else {
      if (defined $self->{_LastHost} && defined $self->{_LastPort}) {
	$self->{_Log}('Disconnected from Notification Server: '. 
	  $self->{_LastHost}. ':'. $self->{_LastPort}. 
	  ' (Socket: '. $fn. ')', 2);
	undef($self->{_LastHost});
	undef($self->{_LastPort});
      } else {
	$self->{_Log}('Disconnected from Notification Server: '.
	  $self->{_Host}. ':'. $self->{_Port}.
	  ' (Socket: '. $fn. ')', 2);
      }
    }

    return $fn;
  } else {
    $self->{_Log}('Cant Disconnect, no socket is open!', 1);
  }
}

sub disconnect_socket {
  my ($self) = @_;

  if (defined $self->{Socket} && $self->{Socket}) {
    $self->remove_socket();
    $self->{Socket}->close();
  }
}

sub connect_socket {
  my ($self, $host, $port) = @_;

  my $socket = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Proto    => 'tcp'
  ) or die "$!";

  my $fn = $socket->fileno;

  if ($self->{_Type} eq 'SB') {
    $self->{_Log}('Connected to Switch Board: '. $host. ':'.
      $port. ' (Handle: '. $self->{Handle}. ', Socket: '. $fn. ')', 2);
  } else {
    $self->{_Log}('Connected to Notification Server: '. $host. ':'.
      $port. ' (Socket: '. $fn. ')', 2);
  }

  return $socket;
}

sub cycle_socket {
  my ($self, $host, $port) = @_;

  ($self->{_LastHost}, $self->{_LastPort}) =
    ($self->{_Host}, $self->{_Port});
  ($self->{_Host}, $self->{_Port}) = ($host, $port);

  $self->disconnect_socket();
  $self->construct_socket();
}

sub send {
  my ($self, $cmd, $data) = @_;

  die "MSN->send: No command specified!\n"
    unless (defined $cmd && $cmd);

  $cmd = (defined $cmd) ? $cmd : '';
  $data = (defined $data) ? $data : '';

  my $datagram = $cmd. ' '. ++$__PACKAGE__::TrID. ' '. $data. "\r\n";

  $self->{Socket}->print($datagram);
  chomp($datagram);
  
  my $fn = $self->{Socket}->fileno;
  
  $self->{_Log}('('. $fn. ')TX: '. $datagram, 3);

  return length($datagram);
}

sub sendraw {
  my ($self, $cmd, $data) = @_;

  die "MSN->send: No command specified!\n"
    unless (defined $cmd && $cmd);

  $cmd = (defined $cmd) ? $cmd : '';
  $data = (defined $data) ? $data : '';

  my $datagram = $cmd. ' '. ++$__PACKAGE__::TrID. ' '. $data;

  $self->{Socket}->print($datagram);
  chomp($datagram);
  
  my $fn = $self->{Socket}->fileno;
  
  $self->{_Log}('('. $fn. ')TX: '. $datagram, 3);

  return length($datagram);
}

sub sendnotrid {
  my ($self, $cmd, $message) = @_;

  die "MSN->send: No command specified!\n"
    unless (defined $cmd && $cmd);

  my $datagram = $cmd;
  $datagram .= ' '. $message if (defined $message && $message);
  $datagram .= "\r\n";

  $self->{Socket}->print($datagram);
  chomp($datagram);
  
  my $fn = $self->{Socket}->fileno;
  
  $self->{_Log}('('. $fn. ')TX: '. $datagram, 3);

  return length($datagram);
}

return 1;
