package Net::Hotline::Client;

## Copyright(c) 1998-2002 by John C. Siracusa.  All rights reserved.  This
## program is free software; you can redistribute it and/or modify it under
## the same terms as Perl itself.

use strict;

use vars qw(@ISA $VERSION $DEBUG);

use Carp;
use IO::File;
use IO::Socket;
use Net::Hotline::User;
use Net::Hotline::Task;
use Net::Hotline::PrivateChat;
use Net::Hotline::FileListItem;
use Net::Hotline::FileInfoItem;
use Net::Hotline::TrackerListItem;
use Net::Hotline::Protocol::Packet;
use Net::Hotline::Protocol::Header;
use Net::Hotline::Shared qw(:all);
use Net::Hotline::Constants qw(:all);

if($^O eq 'MacOS') # "#ifdef", where have you gone...
{
  require Mac::MoreFiles;
  require Mac::Files;
}

use AutoLoader 'AUTOLOAD';

#
# Class attributes
#

$VERSION = '0.83';
$DEBUG   = 0;

# CRC perl code lifted from Convert::BinHex by Eryq (eryq@enteract.com)
# An array useful for CRC calculations that use 0x1021 as the "seed":
my(@CRC_MAGIC) = (
    0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50A5, 0x60C6, 0x70E7,
    0x8108, 0x9129, 0xA14A, 0xB16B, 0xC18C, 0xD1AD, 0xE1CE, 0xF1EF,
    0x1231, 0x0210, 0x3273, 0x2252, 0x52B5, 0x4294, 0x72F7, 0x62D6,
    0x9339, 0x8318, 0xB37B, 0xA35A, 0xD3BD, 0xC39C, 0xF3FF, 0xE3DE,
    0x2462, 0x3443, 0x0420, 0x1401, 0x64E6, 0x74C7, 0x44A4, 0x5485,
    0xA56A, 0xB54B, 0x8528, 0x9509, 0xE5EE, 0xF5CF, 0xC5AC, 0xD58D,
    0x3653, 0x2672, 0x1611, 0x0630, 0x76D7, 0x66F6, 0x5695, 0x46B4,
    0xB75B, 0xA77A, 0x9719, 0x8738, 0xF7DF, 0xE7FE, 0xD79D, 0xC7BC,
    0x48C4, 0x58E5, 0x6886, 0x78A7, 0x0840, 0x1861, 0x2802, 0x3823,
    0xC9CC, 0xD9ED, 0xE98E, 0xF9AF, 0x8948, 0x9969, 0xA90A, 0xB92B,
    0x5AF5, 0x4AD4, 0x7AB7, 0x6A96, 0x1A71, 0x0A50, 0x3A33, 0x2A12,
    0xDBFD, 0xCBDC, 0xFBBF, 0xEB9E, 0x9B79, 0x8B58, 0xBB3B, 0xAB1A,
    0x6CA6, 0x7C87, 0x4CE4, 0x5CC5, 0x2C22, 0x3C03, 0x0C60, 0x1C41,
    0xEDAE, 0xFD8F, 0xCDEC, 0xDDCD, 0xAD2A, 0xBD0B, 0x8D68, 0x9D49,
    0x7E97, 0x6EB6, 0x5ED5, 0x4EF4, 0x3E13, 0x2E32, 0x1E51, 0x0E70,
    0xFF9F, 0xEFBE, 0xDFDD, 0xCFFC, 0xBF1B, 0xAF3A, 0x9F59, 0x8F78,
    0x9188, 0x81A9, 0xB1CA, 0xA1EB, 0xD10C, 0xC12D, 0xF14E, 0xE16F,
    0x1080, 0x00A1, 0x30C2, 0x20E3, 0x5004, 0x4025, 0x7046, 0x6067,
    0x83B9, 0x9398, 0xA3FB, 0xB3DA, 0xC33D, 0xD31C, 0xE37F, 0xF35E,
    0x02B1, 0x1290, 0x22F3, 0x32D2, 0x4235, 0x5214, 0x6277, 0x7256,
    0xB5EA, 0xA5CB, 0x95A8, 0x8589, 0xF56E, 0xE54F, 0xD52C, 0xC50D,
    0x34E2, 0x24C3, 0x14A0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
    0xA7DB, 0xB7FA, 0x8799, 0x97B8, 0xE75F, 0xF77E, 0xC71D, 0xD73C,
    0x26D3, 0x36F2, 0x0691, 0x16B0, 0x6657, 0x7676, 0x4615, 0x5634,
    0xD94C, 0xC96D, 0xF90E, 0xE92F, 0x99C8, 0x89E9, 0xB98A, 0xA9AB,
    0x5844, 0x4865, 0x7806, 0x6827, 0x18C0, 0x08E1, 0x3882, 0x28A3,
    0xCB7D, 0xDB5C, 0xEB3F, 0xFB1E, 0x8BF9, 0x9BD8, 0xABBB, 0xBB9A,
    0x4A75, 0x5A54, 0x6A37, 0x7A16, 0x0AF1, 0x1AD0, 0x2AB3, 0x3A92,
    0xFD2E, 0xED0F, 0xDD6C, 0xCD4D, 0xBDAA, 0xAD8B, 0x9DE8, 0x8DC9,
    0x7C26, 0x6C07, 0x5C64, 0x4C45, 0x3CA2, 0x2C83, 0x1CE0, 0x0CC1,
    0xEF1F, 0xFF3E, 0xCF5D, 0xDF7C, 0xAF9B, 0xBFBA, 0x8FD9, 0x9FF8,
    0x6E17, 0x7E36, 0x4E55, 0x5E74, 0x2E93, 0x3EB2, 0x0ED1, 0x1EF0
);

1;

#
# Non-autoloaded object methods
#

sub new
{
  my($class) = shift;

  my($self) =
  {
    'NICK'         => undef,
    'LOGIN'        => undef,
    'COLOR'        => undef,
    'SERVER_PORT'  => undef,
    'SERVER_ADDR'  => undef,
    'TRACKER_ADDR' => undef,

    'SOCKET'       => undef,
    'BLOCKING'     => 1,
    'SERVER'       => undef,
    'SEQNUM'       => 1,

    'USER_LIST'    => undef,
    'NEWS'         => undef,
    'FILES'        => undef,
    'AGREEMENT'    => undef,
    'PCHATS'       => undef,
    'TASKS'        => undef,

    'FILE_INFO'    => undef,

    'HANDLERS'  =>
    {
      'AGREEMENT'     => undef,
      'BAN'           => undef,
      'CHAT'          => undef,
      'CHAT_ACTION'   => undef,
      'COLOR'         => undef,
      'EVENT'         => undef,
      'FILE_DELETE'   => undef,
      'FILE_GET'      => undef,
      'FILE_GET_INFO' => undef,
      'FILE_LIST'     => undef,
      'FILE_MKDIR'    => undef,
      'FILE_MOVE'     => undef,
      'FILE_SET_INFO' => undef,
      'ICON'          => undef,
      'JOIN'          => undef,
      'KICK'          => undef,
      'LEAVE'         => undef,
      'LOGIN'         => undef,
      'MSG'           => undef,
      'NEWS'          => undef,
      'NEWS_POST'     => undef,
      'NEWS_POSTED'   => undef,
      'NICK'          => undef,
      'PCHAT_ACCEPT'  => undef,
      'PCHAT_CREATE'  => undef,
      'PCHAT_INVITE'  => undef,
      'PCHAT_JOIN'    => undef,
      'PCHAT_LEAVE'   => undef,
      'PCHAT_SUBJECT' => undef,
      'QUIT'          => undef,
      'SEND_MSG'      => undef,
      'SERVER_MSG'    => undef,
      'TASK_ERROR'    => undef,
      'USER_GETINFO'  => undef,
      'USER_LIST'     => undef
    },

    'BLOCKING_TASKS'         => undef,
    'DEFAULT_HANDLERS'       => undef,
    'HANDLERS_WHEN_BLOCKING' => undef,

    'LOGGED_IN'       => undef,

    'EVENT_TIMING'    => 1,
    'CONNECT_TIMEOUT' => 15,
    'PATH_SEPARATOR'  => HTLC_PATH_SEPARATOR,
    'HTXF_BUFSIZE'    => HTXF_BUFSIZE,

    'DOWNLOADS_DIR'   => undef,
    'DATA_FORK_EXT'   => '.data',
    'RSRC_FORK_EXT'   => '.rsrc',

    'LAST_ACTIVITY'   => time(),
    'LAST_ERROR'      => undef,
    'MACOS'           => ($^O eq 'MacOS') ? 1 : 0
  };

  bless  $self, $class;
  return $self;
}

sub agreement { $_[0]->{'AGREEMENT'} }

sub blocking
{
  my($self, $blocking) = @_;

  return $self->{'BLOCKING'}  unless(@_ == 2);

  if(ref($self->{'SERVER'}) && $self->{'SERVER'}->opened())
  {
    _set_blocking($self->{'SERVER'}, $blocking);
  }

  $self->{'BLOCKING'} = (($blocking) ? 1 : 0);
  return $self->{'BLOCKING'};
}

sub blocking_tasks
{
  my($self, $arg) = @_;
  $self->{'BLOCKING_TASKS'} = ($arg) ? 1 : 0  if(@_ == 2);
  return $self->{'BLOCKING_TASKS'};
}

sub connect_timeout
{
  my($self, $secs) = @_;
  $self->{'CONNECT_TIMEOUT'} = $secs  if($secs =~ /^\d+$/);
  return $self->{'CONNECT_TIMEOUT'};
}

sub default_handlers
{
  my($self, $arg) = @_;
  $self->{'DEFAULT_HANDLERS'} = ($arg) ? 1 : 0  if(@_ == 2);
  return $self->{'DEFAULT_HANDLERS'};
}

sub downloads_dir
{
  my($self, $dir) = @_;
  $self->{'DOWNLOADS_DIR'} = $dir  if(-d $dir);
  return $self->{'DOWNLOADS_DIR'};
}

sub data_fork_extension
{
  my($self, $ext) = @_;
  croak("The data fork extension may not be the same as the resource fork extension!")
    if($ext eq $self->{'DATA_FORK_EXT'}); 
  $self->{'DATA_FORK_EXT'} = $ext  if(defined($ext));
  return $self->{'DATA_FORK_EXT'};
}

sub event_timing
{
  my($self, $secs) = @_;

  if(defined($secs))
  {
    croak qw(Bad argument to event_timing() - "$secs")  if($secs =~ /[^0-9.]/);
    $self->{'EVENT_TIMING'} = $secs;
  }

  return $self->{'EVENT_TIMING'};
}

sub files    { $_[0]->{'FILES'}    }
sub handlers { $_[0]->{'HANDLERS'} }

sub handlers_during_blocking_tasks
{
  my($self, $arg) = @_;
  $self->{'HANDLERS_WHEN_BLOCKING'} = ($arg) ? 1 : 0  if(@_ == 2);
  return $self->{'HANDLERS_WHEN_BLOCKING'};
}

sub last_error  { $_[0]->{'LAST_ERROR'} }
sub clear_error { $_[0]->{'LAST_ERROR'} = undef }

sub xfer_bufsize
{
  my($self, $size) = @_;
  $self->{'HTXF_BUFSIZE'} = $size  if($size =~ /^\d+$/);
  return $self->{'HTXF_BUFSIZE'};
}

sub last_activity
{
  my($self) = shift;
  return $self->{'LAST_ACTIVITY'};
}

sub news { $_[0]->{'NEWS'} }

sub path_separator
{
  my($self, $separator) = @_;
  $self->{'PATH_SEPARATOR'} = $separator  if($separator =~ /^.$/);
  return $self->{'PATH_SEPARATOR'};
}

sub rsrc_fork_extension
{
  my($self, $ext) = @_;
  croak("The resource fork extension may not be the same as the data fork extension!")
    if($ext eq $self->{'RSRC_FORK_EXT'}); 
  $self->{'RSRC_FORK_EXT'} = $ext  if(defined($ext));
  return $self->{'RSRC_FORK_EXT'};
}

sub pchats   { $_[0]->{'PCHATS'}      }
sub userlist { $_[0]->{'USER_LIST'}   }

sub server
{
  $_[0]->{'SERVER_ADDR'} .
    ($_[0]->{'SERVER_PORT'} ne HTLS_TCPPORT) ?
      ":$_[0]->{'SERVER_PORT'}" : '';
}

sub connect
{
  my($self, $server) = @_;

  my($address, $port);

  if(($address = $server) =~ s/^([^ :]+)(?:[: ](\d+))?$/$1/)
  {
    $port = $2 || HTLS_TCPPORT;
  }
  else
  {
    croak("Bad server address: $server");
  }

  eval
  {
    $SIG{'ALRM'} = sub { die "timeout" };
    alarm($self->{'CONNECT_TIMEOUT'});

    $self->{'SERVER'} = 
      IO::Socket::INET->new(PeerAddr =>$address,
                            PeerPort =>$port,
                            Proto    =>'tcp');

    alarm(0);
    $SIG{'ALRM'} = 'DEFAULT';
  };

  if($@ =~ /timeout/)
  {
    $self->{'LAST_ERROR'} = "Timed out after $self->{'CONNECT_TIMEOUT'} seconds";
    return;
  }

  if(!$self->{'SERVER'} || $@)
  {
    $self->{'LAST_ERROR'} = $@ || $! || 'Connection failed';
    return;
  }

  $self->{'SERVER'}->autoflush(1);

  $self->{'SERVER_ADDR'} = $address;
  $self->{'SERVER_PORT'} = $port;

  return(1);
}

sub disconnect
{
  my($self) = shift;

  if(ref($self->{'SERVER'}) && $self->{'SERVER'}->opened())
  {
    $self->{'SERVER'}->close();
    $self->{'LOGGED_IN'} = undef;
    $self->{'SERVER_ADDR'} = undef;
    return(1);
  }

  $self->{'LAST_ERROR'} = 'Not connected.';
  return;
}

sub login
{
  my($self, %args) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_login_now(%args); 
  }
  else
  {
    return $self->_login(%args); 
  }
}

sub _login_now
{
  my($self, %args) = @_;

  my($no_news, $no_userlist, $task_num, $task, $packet);

  $no_news     = $args{'NoNews'};
  $no_userlist = $args{'NoUserList'};

  $args{'NoNews'} = $args{'NoUserList'} = undef;

  $task_num = $self->_login(%args);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    $self->disconnect();
    return;
  }

  unless($no_news)
  {
    unless($self->get_news())
    {
      $self->{'LAST_ERROR'} = "Login succeeded, but could not get news.";
      return("0E-0");
    }
  }

  unless($no_userlist)
  {
    unless($self->get_userlist())
    {
      $self->{'LAST_ERROR'} = "Login succeeded, but could not get userlist";
      return("0E-0");
    }
  }

  return(1);
}

sub _login
{
  my($self, %args) = @_;

  my($nick, $login, $password, $icon, $enc_login, $enc_password,
     $proto_header, $data, $response, $task_num, $server);

  $server = $self->{'SERVER'} or croak "Not connected to a server";

  unless($server->opened())
  {
    $self->{'LAST_ERROR'} = "login() called before connect()";
    return;
  }

  $nick  = $args{'Nickname'} || HTLC_DEFAULT_NICK;
  $login = $args{'Login'}    || HTLC_DEFAULT_LOGIN;
  $icon  = $args{'Icon'}     || HTLC_DEFAULT_ICON;
  $password = $args{'Password'};

  $self->{'NICK'}  = $nick;
  $self->{'LOGIN'} = $login;
  $self->{'ICON'}  = $icon;

  _hlc_write($self, $server, \HTLC_MAGIC, HTLC_MAGIC_LEN) || return;
  _hlc_read($self, $server, \$response, HTLS_MAGIC_LEN) || return;

  if($response ne HTLS_MAGIC)
  {
    $self->{'LAST_ERROR'} = "Handshake failed.  Not a hotline server?";
    $self->disconnect();
    return;
  }

  $enc_login    = _encode($login);
  $enc_password = _encode($password);

  $proto_header = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_LOGIN);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_PROTO_HDR + 
                     length($enc_login) +
                     length($enc_password) +
                     length($nick));
  $proto_header->len2($proto_header->len);

  my($fmt) = 'nnna*nna*nna*nnn';

  $data = $proto_header->header() .
          pack($fmt, 0x0004,                  # Num atoms

                     HTLC_DATA_LOGIN,         # Atom type
                     length($enc_login),      # Atom length
                     $enc_login,              # Atom data

                     HTLC_DATA_PASSWORD,      # Atom type
                     length($enc_password),   # Atom length
                     $enc_password,           # Atom data

                     HTLC_DATA_NICKNAME,      # Atom type
                     length($nick),           # Atom length
                     $nick,                   # Atom data

                     HTLC_DATA_ICON,          # Atom type
                     0x0002,                  # Atom length
                     $icon);                  # Atom data

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: LOGIN - $task_num\n");
    $self->{'TASKS'}->{$task_num} =
      new Net::Hotline::Task($task_num, HTLC_TASK_LOGIN, time());
  }
  else { return }

  unless($args{'NoUserList'})
  {
    $self->req_userlist();
  }

  unless($args{'NoNews'})
  {
    $self->req_news();
  }

  _set_blocking($server, $self->{'BLOCKING'});

  return($task_num);
}

sub run
{
  my($self) = shift;

  my($server) = $self->{'SERVER'}  or croak "Not connected to a server";
  return  unless($server->opened());

  my($ret, $packet);

  $packet = new Net::Hotline::Protocol::Packet;

  while($ret = $packet->read_parse($server, $self->{'BLOCKING'}))
  {
    _process_packet($self, $packet, $ret) || return(1);
  }

  return(1);
}

sub _process_packet
{
  my($self, $packet, $ret, $blocking_task) = @_;

  my($data_ref, $type, $use_handlers);

  $use_handlers = !($blocking_task && !$self->{'HANDLERS_WHEN_BLOCKING'});

  $type = $packet->{'TYPE'};

  if($ret == HTLC_EWOULDBLOCK) # Idle event
  {
    if(defined($self->{'HANDLERS'}->{'EVENT'}))
    {
      &{$self->{'HANDLERS'}->{'EVENT'}}($self, 1);
    }

    select(undef, undef, undef, $self->{'EVENT_TIMING'});
    return(1);
  }

  $self->{'LAST_ACTIVITY'} = time();

  if(defined($self->{'HANDLERS'}->{'EVENT'})) # Non-idle event
  {
    &{$self->{'HANDLERS'}->{'EVENT'}}($self, 0);
  }

  _debug("Packet type = $type\n");

  if($type == HTLS_HDR_USER_LEAVE)
  {
    # Hotline server *BUG* - you may get a "disconnect" packet for a
    # socket _before_ you get the "connect" packet for that socket!
    # In fact, the "connect" packet will never arrive in this case.

    if(defined($packet->{'SOCKET'}) &&
       defined($self->{'USER_LIST'}->{$packet->{'SOCKET'}}))
    {
      my($user) = $self->{'USER_LIST'}->{$packet->{'SOCKET'}};

      delete $self->{'USER_LIST'}->{$packet->{'SOCKET'}};

      if($use_handlers)
      {
        if(defined($self->{'HANDLERS'}->{'LEAVE'}))
        {
          &{$self->{'HANDLERS'}->{'LEAVE'}}($self, $user);
        }
        elsif($self->{'DEFAULT_HANDLERS'})
        {       
          print "USER LEFT: ", $user->nick(), "\n";
        }
      }
    }
  }
  elsif($type == HTLS_HDR_TASK)
  {
    my($task) = $self->{'TASKS'}->{$packet->{'TASK_NUM'}};

    my($task_type) = $task->type();

    $task->finish(time());

    if(defined($packet->{'TASK_ERROR'}))
    {
      $task->error(1);
      $task->error_text($packet->{'TASK_ERROR'});

      if($use_handlers)
      {
        if(defined($self->{'HANDLERS'}->{'TASK_ERROR'}))
        {
          &{$self->{'HANDLERS'}->{'TASK_ERROR'}}($self, $task);
        }
        else
        {
          print "TASK ERROR(", $task->num(), ':', $task->type(), ") ",
                $task->error_text(), "\n";
        }
      }
    }
    else
    {
      $task->error(0);

      if($task_type == HTLC_TASK_USER_LIST && defined($packet->{'USER_LIST'}))
      {
        $self->{'USER_LIST'} = $packet->{'USER_LIST'};

        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'USER_LIST'}))
          {
            &{$self->{'HANDLERS'}->{'USER_LIST'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "GET USER LIST: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_FILE_LIST)
      {
        my($path);

        $task->path("")  unless(length($task->path()));
        $path = $task->path();

        if($packet->{'FILE_LIST'})
        {
          $self->{'FILES'}->{$path} = $packet->{'FILE_LIST'};
        }
        else
        {
          $self->{'FILES'}->{$path} = [];
        }

        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'FILE_LIST'}))
          {
            &{$self->{'HANDLERS'}->{'FILE_LIST'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "GET FILE LIST: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_NEWS && defined($packet->{'DATA'}))
      {
        my(@news) = split(/_{58}/, $packet->{'DATA'});

        $self->{'NEWS'} = \@news;

        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'NEWS'}))
          {
            &{$self->{'HANDLERS'}->{'NEWS'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "GET NEWS: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_USER_INFO && defined($packet->{'DATA'}))
      {
        my($user) = $self->{'USER_LIST'}->{$task->socket()};

        $user->info($packet->{'DATA'});

        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'USER_GETINFO'}))
          {
            &{$self->{'HANDLERS'}->{'USER_GETINFO'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "GET USER INFO: Task complete.\n";
          }
        }

        _debug("USER_GETINFO for: $packet->{'NICK'} (", $task->socket(), ")\n",
               $packet->{'DATA'}, "\n");
      }
      elsif($task_type == HTLC_TASK_FILE_INFO)
      {
        my($path, $file_info);

        $task->path("")  unless(length($task->path));
        $path = $task->path();

        $file_info = $self->{'FILE_INFO'} = new Net::Hotline::FileInfoItem();

        $file_info->icon($packet->{'FILE_ICON'});
        $file_info->type($packet->{'FILE_TYPE'});
        $file_info->creator($packet->{'FILE_CREATOR'});
        $file_info->size($packet->{'FILE_SIZE'});
        $file_info->name($packet->{'FILE_NAME'});
        $file_info->comment($packet->{'FILE_COMMENT'});
        $file_info->ctime($packet->{'FILE_CTIME'});
        $file_info->mtime($packet->{'FILE_MTIME'});

        if($use_handlers)
        {      
          if(defined($self->{'HANDLERS'}->{'FILE_GET_INFO'}))
          {
            &{$self->{'HANDLERS'}->{'FILE_GET_INFO'}}($self, $task, $file_info);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "FILE_GET_INFO: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_LOGIN)
      {
        $self->{'LOGGED_IN'} = 1;

        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'LOGIN'}))
          {
            &{$self->{'HANDLERS'}->{'LOGIN'}}($self);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "LOGIN: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_NEWS_POST)
      {
        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'NEWS_POST'}))
          {
            &{$self->{'HANDLERS'}->{'NEWS_POST'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "POST NEWS: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_SEND_MSG)
      {
        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'SEND_MSG'}))
          {
            &{$self->{'HANDLERS'}->{'SEND_MSG'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "SEND MSG: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_KICK)
      {
        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'KICK'}))
          {
            &{$self->{'HANDLERS'}->{'KICK'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "KICK: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_BAN)
      {
        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'BAN'}))
          {
            &{$self->{'HANDLERS'}->{'BAN'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "BAN: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_SET_INFO)
      {
        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'FILE_SET_INFO'}))
          {
            &{$self->{'HANDLERS'}->{'FILE_SET_INFO'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "SET INFO: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_FILE_DELETE)
      {
        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'FILE_DELETE'}))
          {
            &{$self->{'HANDLERS'}->{'FILE_DELETE'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "DELETE FILE: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_FILE_MKDIR)
      {
        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'FILE_MKDIR'}))
          {
            &{$self->{'HANDLERS'}->{'FILE_MKDIR'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "CREATE FOLDER: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_FILE_MOVE)
      {
        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'FILE_MOVE'}))
          {
            &{$self->{'HANDLERS'}->{'FILE_MOVE'}}($self, $task);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "MOVE FILE: Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_FILE_GET)
      {
        my($size) = $packet->{'HTXF_SIZE'};
        my($ref)  = $packet->{'HTXF_REF'};

        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'FILE_GET'}))
          {
            &{$self->{'HANDLERS'}->{'FILE_GET'}}($self, $task, $ref, $size);
          }
          else
          {
            print "GET FILE: Starting download (ref = $ref, size = $size)\n"
              if($self->{'DEFAULT_HANDLERS'});

            $self->recv_file($task, $ref, $size);
          }
        }
      }
      elsif($task_type == HTLC_TASK_FILE_PUT)
      {
        my($ref)    = $packet->{'HTXF_REF'};
        my($resume) = $packet->{'HTXF_RFLT'};
        my($size)   = ${$task->misc()}[0] + ${$task->misc()}[1];

        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'FILE_PUT'}))
          {
            &{$self->{'HANDLERS'}->{'FILE_PUT'}}($self, $task, $ref, $size, $resume);
          }
          else
          {
            print "GET PUT: Starting upload (ref = $ref)\n"
              if($self->{'DEFAULT_HANDLERS'});

            $self->send_file($task, $ref, $size, $resume);
          }
        }
      }
      elsif($task_type == HTLC_TASK_PCHAT_CREATE)
      {
        my($ref)    = $packet->{'PCHAT_REF'};
        my($user)   = $self->{'USER_LIST'}->{$packet->{'SOCKET'}};
        my($pchat)  = $self->{'PCHATS'}->{$ref} = new Net::Hotline::PrivateChat;

        $pchat->reference($ref);
        $pchat->userlist({ $packet->{'SOCKET'} => $user });

        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'PCHAT_CREATE'}))
          {
            &{$self->{'HANDLERS'}->{'PCHAT_CREATE'}}($self, $task, $pchat);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "CREATE PCHAT($ref): Task complete.\n";
          }
        }
      }
      elsif($task_type == HTLC_TASK_PCHAT_ACCEPT)
      {
        my($ref) = $task->misc();

        my($userlist);
        
        # Create userlist of references to the main userlist rather
        # than new user objects (as returned in the packet)
        foreach my $socket (keys(%{$packet->{'USER_LIST'}}))
        {
          $userlist->{$socket} = $self->{'USER_LIST'}->{$socket};
        }

        my($pchat)  = $self->{'PCHATS'}->{$ref} =
          new Net::Hotline::PrivateChat($ref, $userlist);
        
        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'PCHAT_ACCEPT'}))
          {
            &{$self->{'HANDLERS'}->{'PCHAT_ACCEPT'}}($self, $task, $pchat);
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "ACCEPT PCHAT INVITE($ref): Task complete.\n";
          }
        }
      }
    }
    # Reclaim memory
    delete $self->{'TASKS'}->{$packet->{'TASK_NUM'}};
  }
  elsif($type == HTLS_HDR_AGREEMENT)
  {
    $self->{'AGREEMENT'} = $packet->{'DATA'};

    if(defined($packet->{'DATA'}))
    {
      if($use_handlers)
      {
        if(defined($self->{'HANDLERS'}->{'AGREEMENT'}))
        {
          &{$self->{'HANDLERS'}->{'AGREEMENT'}}($self, \$packet->{'DATA'});
        }
        elsif($self->{'DEFAULT_HANDLERS'})
        {
          print "AGREEMENT:\n", $packet->{'DATA'}, "\n";
        }
      }
    }
  }
  elsif($type == HTLS_HDR_MSG)
  {
    my($user) = $self->{'USER_LIST'}->{$packet->{'SOCKET'}};

    # User-to-user message
    if(defined($user) && defined($packet->{'DATA'}))
    {
      if($use_handlers)
      {
        if(defined($self->{'HANDLERS'}->{'MSG'}))
        {
          &{$self->{'HANDLERS'}->{'MSG'}}($self, $user, \$packet->{'DATA'}, \$packet->{'REPLY_TO'});
        }
        elsif($self->{'DEFAULT_HANDLERS'})
        {
          print "MSG: ", $user->nick(), "(", 
                         $packet->{'SOCKET'}, ") ", 
                         $packet->{'DATA'};

          if($packet->{'IS_REPLY'})
          {
            print " (In reply to: $packet->{'REPLY_TO'}])";
          }

          print "\n";
        }
      }
    }
    elsif(defined($packet->{'DATA'})) # Server message
    {
      if($use_handlers)
      {
        if(defined($self->{'HANDLERS'}->{'SERVER_MSG'}))
        {
          &{$self->{'HANDLERS'}->{'SERVER_MSG'}}($self, \$packet->{'DATA'});
        }
        elsif($self->{'DEFAULT_HANDLERS'})
        {
          print "SERVER MSG: ", $packet->{'DATA'}, "\n";
        }
      }
    }
  }
  elsif($type == HTLS_HDR_USER_CHANGE)
  {
    if(defined($packet->{'NICK'}) && defined($packet->{'SOCKET'}) &&
       defined($packet->{'ICON'}) && defined($packet->{'COLOR'}))
    {
      if(defined($self->{'USER_LIST'}->{$packet->{'SOCKET'}}))
      {
        my($user) = $self->{'USER_LIST'}->{$packet->{'SOCKET'}};

        if($user->nick() ne $packet->{'NICK'})
        {
          my($old_nick) = $user->nick();

          $user->nick($packet->{'NICK'});

          if($use_handlers)
          {
            if(defined($self->{'HANDLERS'}->{'NICK'}))
            {
              &{$self->{'HANDLERS'}->{'NICK'}}($self, $user, $old_nick, $user->nick());
            }
            elsif($self->{'DEFAULT_HANDLERS'})
            {
              print "USER CHANGE: $old_nick is now known as ", $user->nick(), "\n";
            }
          }
        }
        elsif($user->icon() ne $packet->{'ICON'})
        {
          my($old_icon) = $user->icon();

          $user->icon($packet->{'ICON'});

          if($use_handlers)
          {
            if(defined($self->{'HANDLERS'}->{'ICON'}))
            {
              &{$self->{'HANDLERS'}->{'ICON'}}($self, $user, $old_icon, $user->icon());
            }
            elsif($self->{'DEFAULT_HANDLERS'})
            {
              print "USER CHANGE: ", $user->nick(),
                    " icon changed from $old_icon to ",
                    $user->icon(), "\n";
            }
          }
        }
        elsif($user->color() ne $packet->{'COLOR'})
        {
          my($old_color) = $user->color();

          $user->color($packet->{'COLOR'});

          if($use_handlers)
          {
            if(defined($self->{'HANDLERS'}->{'COLOR'}))
            {
              &{$self->{'HANDLERS'}->{'COLOR'}}($self, $user, $old_color, $user->color());
            }
            elsif($self->{'DEFAULT_HANDLERS'})
            {
              print "USER CHANGE: ", $user->nick(),
                    " color changed from $old_color to ",
                    $user->color(), "\n";
            }
          }
        }
      }
      else
      {
        $self->{'USER_LIST'}->{$packet->{'SOCKET'}} =
          new Net::Hotline::User($packet->{'SOCKET'},
                            $packet->{'NICK'},
                            undef,
                            $packet->{'ICON'},
                            $packet->{'COLOR'});

        if($use_handlers)
        {
          if(defined($self->{'HANDLERS'}->{'JOIN'}))
          {
            &{$self->{'HANDLERS'}->{'JOIN'}}($self, $self->{'USER_LIST'}->{$packet->{'SOCKET'}});
          }
          elsif($self->{'DEFAULT_HANDLERS'})
          {
            print "JOINED:\n",
                  "  Nick: $packet->{'NICK'}\n",
                  "  Icon: $packet->{'ICON'}\n",
                  "Socket: $packet->{'SOCKET'}\n",
                  " Color: $packet->{'COLOR'}\n";
          }
        }
      }
    }
  }
  elsif($type == HTLS_HDR_CHAT)
  {
    if(defined($packet->{'DATA'}))
    {
      $packet->{'DATA'} =~ s/^\n//s;

      my($ref) = $packet->{'PCHAT_REF'};

      if($ref) # Priate chat
      {
        # Private chat "action"
        if($packet->{'DATA'} =~ /^ \*\*\* /)
        {
          if($use_handlers)
          {
            if(defined($self->{'HANDLERS'}->{'PCHAT_ACTION'}))
            {
              &{$self->{'HANDLERS'}->{'PCHAT_ACTION'}}($self, $ref, \$packet->{'DATA'});
            }
            elsif($self->{'DEFAULT_HANDLERS'})
            {
              print "PCHAT($ref) ACTION: ", $packet->{'DATA'}, "\n";
            }
          }
        }
        else # Regular private chat
        {
          if($use_handlers)
          {
            if(defined($self->{'HANDLERS'}->{'PCHAT_CHAT'}))
            {
              &{$self->{'HANDLERS'}->{'PCHAT_CHAT'}}($self, $ref, \$packet->{'DATA'});
            }
            elsif($self->{'DEFAULT_HANDLERS'})
            {
              print "PCHAT($ref): ", $packet->{'DATA'}, "\n";
            }
          }
        }
      }
      else # Regular chat
      {
        # Chat "action"
        if($packet->{'DATA'} =~ /^ \*\*\* /)
        {
          if($use_handlers)
          {
            if(defined($self->{'HANDLERS'}->{'CHAT_ACTION'}))
            {
              &{$self->{'HANDLERS'}->{'CHAT_ACTION'}}($self, \$packet->{'DATA'});
            }
            elsif($self->{'DEFAULT_HANDLERS'})
            {
              print "CHAT ACTION: ", $packet->{'DATA'}, "\n";
            }
          }
        }
        else # Regular chat
        {
          if($use_handlers)
          {
            if(defined($self->{'HANDLERS'}->{'CHAT'}))
            {
              &{$self->{'HANDLERS'}->{'CHAT'}}($self, \$packet->{'DATA'});
            }
            elsif($self->{'DEFAULT_HANDLERS'})
            {
              print "CHAT: ", $packet->{'DATA'}, "\n";
            }
          }
        }
      }
    }
  }
  elsif($type == HTLS_HDR_NEWS_POST)
  {
    my($post) = $packet->{'DATA'};

    if(defined($post))
    {
      $post =~ s/@{[HTLC_NEWLINE]}/\n/osg;
      $post =~ s/_{58}//sg;

      if($use_handlers)
      {
        if(defined($self->{'HANDLERS'}->{'NEWS_POSTED'}))
        {
          &{$self->{'HANDLERS'}->{'NEWS_POSTED'}}($self, \$post);
        }
        elsif($self->{'DEFAULT_HANDLERS'})
        {
          print "NEWS: New post made.\n";
        }
      }
    }
  }
  elsif($type == HTLS_HDR_POLITE_QUIT ||
        $type eq 'DISCONNECTED')
  {
    if(defined($packet->{'DATA'}))
    {
      if($use_handlers)
      {
        if(defined($self->{'HANDLERS'}->{'QUIT'}))
        {
          &{$self->{'HANDLERS'}->{'QUIT'}}($self, \$packet->{'DATA'});
        }
        elsif($self->{'DEFAULT_HANDLERS'})
        {
          print "CONNECTION CLOSED: ", $packet->{'DATA'}, "\n";
        }
      }
    }
    elsif($self->{'DEFAULT_HANDLERS'})
    {
      if($use_handlers)
      {
        print "CONNECTION CLOSED\n";
      }
    }

    $self->disconnect();
    return(0);
  }
  elsif($type == HTLS_HDR_PCHAT_INVITE)
  {
    if($use_handlers)
    {
      if(defined($self->{'HANDLERS'}->{'PCHAT_INVITE'}))
      {
        &{$self->{'HANDLERS'}->{'PCHAT_INVITE'}}($self, $packet->{'PCHAT_REF'},
                                                 $packet->{'SOCKET'},
                                                 $packet->{'NICK'});
      }
      elsif($self->{'DEFAULT_HANDLERS'})
      {
        print "PCHAT INVITE($packet->{'PCHAT_REF'}) from $packet->{'NICK'}($packet->{'SOCKET'})",
              "($packet->{'SOCKET)'})\n";
      }
    }
  }
  elsif($type == HTLS_HDR_PCHAT_USER_JOIN)
  {
    my($ref)    = $packet->{'PCHAT_REF'};
    my($socket) = $packet->{'SOCKET'};
    my($pchat)  = $self->{'PCHATS'}->{$ref};

    $pchat->userlist()->{$socket} = $self->{'USER_LIST'}->{$socket};

    if($use_handlers)
    {
      if(defined($self->{'HANDLERS'}->{'PCHAT_JOIN'}))
      {
        &{$self->{'HANDLERS'}->{'PCHAT_JOIN'}}($self, $pchat, $socket);
      }
      elsif($self->{'DEFAULT_HANDLERS'})
      {
        print "PCHAT($ref)  JOIN($socket)\n";
      }
    }
  }
  elsif($type == HTLS_HDR_PCHAT_USER_LEAVE)
  {
    my($ref)    = $packet->{'PCHAT_REF'};
    my($socket) = $packet->{'SOCKET'};
    my($pchat)  = $self->{'PCHATS'}->{$ref};

    delete $pchat->userlist()->{$socket};

    if($use_handlers)
    {
      if(defined($self->{'HANDLERS'}->{'PCHAT_LEAVE'}))
      {
        &{$self->{'HANDLERS'}->{'PCHAT_LEAVE'}}($self, $pchat, $socket);
      }
      elsif($self->{'DEFAULT_HANDLERS'})
      {
        print "PCHAT($ref)  LEAVE($socket)\n";
      }
    }
  }
  elsif($type == HTLS_HDR_PCHAT_SUBJECT)
  {
    my($pchat) = $self->{'PCHATS'}->{$packet->{'PCHAT_REF'}};
    
    $pchat->subject($packet->{'DATA'});

    if($use_handlers)
    {
      if(defined($self->{'HANDLERS'}->{'PCHAT_SUBJECT'}))
      {
        &{$self->{'HANDLERS'}->{'PCHAT_SUBJECT'}}($self, $pchat, \$packet->{'DATA'});
      }
      elsif($self->{'DEFAULT_HANDLERS'})
      {
        print "PCHAT(", $pchat->reference(), ") Subject set to: $packet->{'DATA'}\n";
      }
    }
  }

  return(1);
}

sub _handler
{
  my($self, $code_ref, $type) = @_;

  if(defined($code_ref))
  {
    if(ref($code_ref) eq 'CODE')
    {
      $self->{'HANDLERS'}->{$type} = $code_ref;
    }
  }

  return $self->{'HANDLERS'}->{$type};
}

sub _next_seqnum
{
  my($self) = shift;

  return $self->{'SEQNUM'}++;
}

sub agreement_handler     { return _handler($_[0], $_[1], 'AGREEMENT')     }
sub ban_handler           { return _handler($_[0], $_[1], 'BAN')           }
sub chat_handler          { return _handler($_[0], $_[1], 'CHAT')          }
sub chat_action_handler   { return _handler($_[0], $_[1], 'CHAT_ACTION')   }
sub color_handler         { return _handler($_[0], $_[1], 'COLOR')         }
sub event_loop_handler    { return _handler($_[0], $_[1], 'EVENT')         }
sub delete_file_handler   { return _handler($_[0], $_[1], 'FILE_DELETE')   }
sub get_file_handler      { return _handler($_[0], $_[1], 'FILE_GET')      }
sub put_file_handler      { return _handler($_[0], $_[1], 'FILE_PUT')      }
sub file_info_handler     { return _handler($_[0], $_[1], 'FILE_GET_INFO') }
sub file_list_handler     { return _handler($_[0], $_[1], 'FILE_LIST')     }
sub new_folder_handler    { return _handler($_[0], $_[1], 'FILE_MKDIR')    }
sub move_file_handler     { return _handler($_[0], $_[1], 'FILE_MOVE')     }
sub set_file_info_handler { return _handler($_[0], $_[1], 'FILE_SET_INFO') }
sub icon_handler          { return _handler($_[0], $_[1], 'ICON')          }
sub join_handler          { return _handler($_[0], $_[1], 'JOIN')          }
sub kick_handler          { return _handler($_[0], $_[1], 'KICK')          }
sub leave_handler         { return _handler($_[0], $_[1], 'LEAVE')         }
sub login_handler         { return _handler($_[0], $_[1], 'LOGIN')         }
sub msg_handler           { return _handler($_[0], $_[1], 'MSG')           }
sub news_handler          { return _handler($_[0], $_[1], 'NEWS')          }
sub post_news_handler     { return _handler($_[0], $_[1], 'NEWS_POST')     }
sub news_posted_handler   { return _handler($_[0], $_[1], 'NEWS_POSTED')   }
sub nick_handler          { return _handler($_[0], $_[1], 'NICK')          }
sub pchat_accept_handler  { return _handler($_[0], $_[1], 'PCHAT_ACCEPT')  }
sub pchat_action_handler  { return _handler($_[0], $_[1], 'PCHAT_ACTION')  }
sub pchat_chat_handler    { return _handler($_[0], $_[1], 'PCHAT_CHAT')    }
sub pchat_create_handler  { return _handler($_[0], $_[1], 'PCHAT_CREATE')  }
sub pchat_invite_handler  { return _handler($_[0], $_[1], 'PCHAT_INVITE')  }
sub pchat_join_handler    { return _handler($_[0], $_[1], 'PCHAT_JOIN')    }
sub pchat_leave_handler   { return _handler($_[0], $_[1], 'PCHAT_LEAVE')   }
sub pchat_subject_handler { return _handler($_[0], $_[1], 'PCHAT_SUBJECT') }
sub quit_handler          { return _handler($_[0], $_[1], 'QUIT')          }
sub send_msg_handler      { return _handler($_[0], $_[1], 'SEND_MSG')      }
sub server_msg_handler    { return _handler($_[0], $_[1], 'SERVER_MSG')    }
sub task_error_handler    { return _handler($_[0], $_[1], 'TASK_ERROR')    }
sub user_info_handler     { return _handler($_[0], $_[1], 'USER_GETINFO')  }
sub user_list_handler     { return _handler($_[0], $_[1], 'USER_LIST')     }

#
# Package subroutines
#

sub version { $Net::Hotline::Client::VERSION }

sub debug
{ 
  if(@_ == 1 && !ref($_[0]))
  {
    $Net::Hotline::Client::DEBUG = ($_[0]) ? 1 : 0;
  }
  elsif(@_ == 2 && ref($_[0]) eq 'Net::Hotline::Client')
  {
    $Net::Hotline::Client::DEBUG = ($_[1]) ? 1 : 0;
  }

  return $Net::Hotline::Client::DEBUG;
}

sub _hlc_write
{
  my($self, $fh, $data_ref, $len) = @_;

  return("0-E0")  if($len == 0 || !defined($len));
  
  unless(_write($fh, $data_ref, $len) == $len)
  {
    $self->{'LAST_ERROR'} = "Write error: $!";
    return;
  }

  return($len);
}

sub _hlc_read
{
  my($self, $fh, $data_ref, $len) = @_;

  return("0-E0")  if($len == 0 || !defined($len));

  unless(_read($fh, $data_ref, $len) == $len)
  {
    $self->{'LAST_ERROR'} = "Read error: $!";
    return;
  }

  return($len);
}

sub _hlc_buffered_read
{
  my($self, $fh, $data_ref, $len) = @_;

  return("0-E0")  if($len == 0 || !defined($len));

  unless(read($fh, $$data_ref, $len) == $len)
  {
    $self->{'LAST_ERROR'} = "Read error: $!";
    return;
  }

  return($len);
}

# Macbinary CRC perl code from Convert::BinHex by Eryq (eryq@enteract.com)
# (It needs access to the lexical @CRC_MAGIC, so it can't be auto-loaded)
sub macbin_crc
{
  shift if(ref($_[0]));

  my($len) = length($_[0]);
  my($crc) = $_[1];

  for(my $i = 0; $i < $len; $i++)
  {
    ($crc ^= (vec($_[0], $i, 8) << 8)) &= 0xFFFF;
    $crc = ($crc << 8) ^ $CRC_MAGIC[$crc >> 8];
  }
  return $crc;
}

#
# Satisfy autoloader's ridiculous *8-character* unique name limit :-/
#

sub get_filelist { al01_get_filelist(@_) }
sub get_fileinfo { al02_get_fileinfo(@_) }
sub get_userinfo { al03_get_userinfo(@_) }
sub user_by_nick { al04_user_by_nick(@_) }
sub req_userlist { al05_req_userlist(@_) }
sub req_filelist { al06_req_filelist(@_) }
sub pchat_action { al07_pchat_action(@_) }
sub get_file     { al08_get_file(@_)     }
sub put_file     { al09_put_file(@_)     }

# Internal functions that were also munged up:

# _al01_put_file_resume_now
# _al02_get_file_resume_now
# _al03_delete_file_now
# _al04_new_folder_now
# _al05_put_file_now
# _al06_put_file_resume
# _al07_get_file_now
# _al08_get_file_resume
# _al09_file_action_stub
# _al10_post_news_now
# _al11_pchat_invite_now
# _al12_pchat_accept_now
# _al13_comment_now

__END__

#
# Auto-loaded methods and subroutines
#

sub logged_in { $_[0]->{'LOGGED_IN'} }

sub connected
{
  (ref($_[0]->{'SERVER'}) && $_[0]->{'SERVER'}->opened()) ? 1 : 0;
}

sub _blocking_task
{
  my($self, $task_num) = @_;

  my($packet, $ret);

  $packet = new Net::Hotline::Protocol::Packet;

  while($ret = $packet->read_parse($self->{'SERVER'}, $self->{'BLOCKING'}))
  {
    _process_packet($self, $packet, $ret, 'blocking task');

    if($packet->{'TYPE'} == HTLS_HDR_TASK &&
       $packet->{'TASK_NUM'} == $task_num)
    {
      return($packet);
    }
  }
}

sub al01_get_filelist
{
  my($self, $path) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->req_filelist($path);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return(0);
  }

  $path = $task->path();
  $path = ""  unless(length($path));

  if(wantarray)
  {
    return @{$self->{'FILES'}->{$path}};
  }
  else
  {
    return $self->{'FILES'}->{$path};
  }
}

sub al06_req_filelist
{
  my($self, $path) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  my($data, $task_num, @path_parts, $path_part, $data_length, $length,
     $save_path);

  $path =~ s/^$self->{'PATH_SEPARATOR'}//;
  $path =~ s/$self->{'PATH_SEPARATOR'}$//;

  if(length($path))
  {
    $save_path = $path;
    @path_parts = split($self->{'PATH_SEPARATOR'}, $path);
    $path =~ s/$self->{'PATH_SEPARATOR'}//g;

    if(length($path) > HTLC_MAX_PATHLEN)
    {
      croak("Maximum path length exceeded");
    }

    # 2 null bytes, the 1 byte for length, and the length of the path part
    $data_length = (3 * scalar(@path_parts)) + length($path);
    $length = SIZEOF_HL_LONG_HDR + $data_length;
  }
  else
  {
    $length = 2; # Two null bytes
  }

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_FILE_LIST);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len($length);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header();

  if(length($path))
  {
    $data .= pack("n4", 0x0001,               # Number of atoms
                        HTLC_DATA_DIRECTORY,  # Atom type
                        $data_length + 2,     # Atom length

                        scalar(@path_parts)); # Number of path parts

    foreach $path_part (@path_parts)          # Path parts data
    {
      if(length($path_part) > HTLC_MAX_PATHLEN)
      {
        croak("Maximum path part length exceeded");
      }

      $data .= pack("nCa*", 0x0000,           # 2 null bytes
                            length $path_part,# Length
                            $path_part);      # Path part
    }
  }
  else
  {
    $data .= pack("n", 0x0000);
  }

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: FILE_LIST - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Net::Hotline::Task($task_num, HTLC_TASK_FILE_LIST, time(), undef, $save_path);
    return($task_num);
  }
  else { return }
}

sub al03_get_userinfo
{
  my($self, $socket) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->req_userinfo($socket);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return $self->{'USER_LIST'}->{$task->socket()}->info();
}

sub req_userinfo
{
  my($self, $socket) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  my($data, $task_num);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_USER_GETINFO);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_LONG_HDR);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n4", 0x0001,                  # Number of atoms

                     HTLC_DATA_SOCKET,        # Atom type
                     0x0002,                  # Atom length
                     $socket);                # Atom data

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: USER_GETINFO - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Net::Hotline::Task($task_num, HTLC_TASK_USER_INFO, time(), $socket);
    return($task_num);
  }
  else { return }
}

sub al02_get_fileinfo
{
  my($self, $path) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->req_fileinfo($path);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return $self->{'FILE_INFO'};
}

sub req_fileinfo
{
  return _file_action_simple($_[0], $_[1], HTLC_HDR_FILE_GETINFO, HTLC_TASK_FILE_INFO, 'GET FILE INFO');
}

sub delete_file
{
  my($self, $path) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_al03_delete_file_now($path); 
  }
  else
  {
    return $self->_delete_file($path); 
  }
}

sub _al03_delete_file_now
{
  my($self, $path) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->_delete_file($path);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return(1);
}

sub _delete_file
{
  return _file_action_simple($_[0], $_[1], HTLC_HDR_FILE_DELETE, HTLC_TASK_FILE_DELETE, 'DELETE FILE');
}

sub new_folder
{
  my($self, $path) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_al04_new_folder_now($path); 
  }
  else
  {
    return $self->_new_folder($path); 
  }
}

sub _al04_new_folder_now
{
  my($self, $path) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->_new_folder($path);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return(1);
}

sub _new_folder
{
  return _file_action_simple($_[0], $_[1], HTLC_HDR_FILE_MKDIR, HTLC_TASK_FILE_MKDIR, 'NEW FOLDER');
}

sub al09_put_file
{
  my($self, $src_path, $dest_path, $comments) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_al05_put_file_now($src_path, $dest_path, $comments); 
  }
  else
  {
    return $self->_put_file($src_path, $dest_path, $comments);
  }
}

sub _al05_put_file_now
{
  my($self, $src_path, $dest_path, $comments) = @_;

  my($task, $task_num, $packet, $size);

  $task_num = $self->_put_file($src_path, $dest_path);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  $size = ${$task->misc()}[0] + ${$task->misc()}[1];

  if(wantarray)
  {
    return($task, $packet->{'HTXF_REF'}, $size);
  }
  else
  {
    return [ $task, $packet->{'HTXF_REF'}, $size ];
  }
}

sub _put_file
{
  my($self, $src_path, $dest_path, $comments) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  croak("Not connected.")  unless($server->opened());

  unless(-e $src_path)
  {
    $self->{'LAST_ERROR'} = "File does not exist: $src_path";
    return;
  }

  my($local_sep, $remote_sep, $src_file, $data, $task_num, $length,
     $num_atoms, $data_len, $rsrc_len, $finder_flags, $type, $creator);

  $local_sep = PATH_SEPARATOR;
  $remote_sep = $self->{'PATH_SEPARATOR'};

  ($src_file = $src_path) =~ s/.*?$local_sep([^$local_sep]+)$/$1/o;
  $dest_path = "$dest_path$remote_sep$src_file";

  ($data, $task_num) = _al09_file_action_stub($self, $dest_path, HTLC_HDR_FILE_PUT);

  # Set new length: old length plus 8 bytes for the size atom
  $length    = (unpack("N", substr($data, 16, 4)) + 8);
  substr($data, 16, 4) = pack("N", $length);
  substr($data, 12, 4) = pack("N", $length);

  # Set new num atoms: old num atoms + 1
  $num_atoms = (unpack("n", substr($data, 20, 2)) + 1);
  substr($data, 20, 2) = pack("n", $num_atoms);

  # Fork lengths
  $data_len = (stat($src_path))[7];
  $rsrc_len = 0;

  # Mac OS specific information: resource fork length and finder comments
  if($self->{'MACOS'})
  {
    my($fsspec, $finder_comments, $res_fd, $rsrc_fh, $cat, $finfo);

    $fsspec = MacPerl::MakeFSSpec($src_path);

    # Get finder comments
    unless(defined($comments))
    {
      $finder_comments = Mac::MoreFiles::FSpDTGetComment($fsspec);
      $comments = $finder_comments  if(length($finder_comments));
    }

    $cat   = Mac::Files::FSpGetCatInfo($fsspec);
    $finfo = $cat->ioFlFndrInfo();

    # Get finder flags, type, and creator
    $finder_flags = $finfo->fdFlags();
    $type         = $finfo->fdType();
    $creator      = $finfo->fdCreator();

    # Protect from compile-time errors on non-Mac OS systems that don't
    # define O_RSRC in Fcntl
    eval '$res_fd = POSIX::open($src_path, O_RDONLY | O_RSRC)';

    $rsrc_fh = new IO::File;

    unless($rsrc_fh->fdopen($res_fd, "r"))
    {
      $self->{'LAST_ERROR'} = "Couldn't open Mac resource fork: $@";
      return;    
    }

    $rsrc_fh->seek(0, SEEK_END);    # Fast forward to end
    $rsrc_len = $rsrc_fh->tell();   # Get size
    $rsrc_fh->seek(0, SEEK_SET);    # Rewind
  }
  else
  {
    ($type, $creator) = ("BINA", "????");
  }

  # Total length of the upload to come: 111 bytes for type/creator/etc.
  # + 1 byte for the file name length + the file name + 2 bytes for the
  # comments length + the comments + 2 fork headers + the size of the
  # file to be uploaded (size of data fork plus size of resource fork).
  $length = (SIZEOF_HL_FILE_UPLOAD_HDR + 1 + length($src_file) + 2 +
             length($comments) + (2 * SIZEOF_HL_FILE_FORK_HDR) +
             $data_len + $rsrc_len);

  # 00 00 00 CB  00 00 00 06  00 00 00 00  00 00 00 21  ...............!
  # 00 00 00 21  00 03 00 C9  00 05 74 65  78 74 32 00  ...!......text2.
  # CA 00 0C 00  01 00 00 07  55 70 6C 6F  61 64 73 00  ........Uploads.
  # 6C 00 02 03  94                                     l....

  # Add size argument
  $data .= pack("nnN", HTLC_DATA_HTXF_SIZE,   # Atom type
                       0x0004,                # Atom length
                       $length);              # Atom data

  _debug(_hexdump($data));

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: PUT FILE - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Net::Hotline::Task($task_num, HTLC_TASK_FILE_PUT, time(), undef,
                             [ $src_path, $dest_path ],
                             [ $data_len, $rsrc_len, $comments, $finder_flags,
                               $type, $creator, $length ]);
    return($task_num);
  }
  else { return }
}

sub put_file_resume
{
  my($self, $src_path, $dest_path, $comments) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_al01_put_file_resume_now($src_path, $dest_path, $comments); 
  }
  else
  {
    return $self->_al06_put_file_resume($src_path, $dest_path, $comments); 
  }
}

sub _al01_put_file_resume_now
{
  my($self, $src_path, $dest_path, $comments) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->_al06_put_file_resume($src_path, $dest_path, $comments);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  if(wantarray)
  {
    return($task, $packet->{'HTXF_REF'}, ${$task->misc()}[6], $packet->{'HTXF_RFLT'});
  }
  else
  {
    return [ $task, $packet->{'HTXF_REF'}, ${$task->misc()}[6], $packet->{'HTXF_RFLT'} ];
  }
}

sub _al06_put_file_resume
{
  my($self, $src_path, $dest_path, $comments) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  croak("Not connected.")  unless($server->opened());

  unless(-e $src_path)
  {
    $self->{'LAST_ERROR'} = "File does not exist: $src_path";
    return;
  }

  my($local_sep, $remote_sep, $src_file, $data, $task_num, $length,
     $num_atoms, $data_len, $rsrc_len, $finder_flags, $type, $creator);

  $local_sep = PATH_SEPARATOR;
  $remote_sep = $self->{'PATH_SEPARATOR'};

  ($src_file = $src_path) =~ s/.*?$local_sep([^$local_sep]+)$/$1/o;
  $dest_path = "$dest_path$remote_sep$src_file";

  ($data, $task_num) = _al09_file_action_stub($self, $dest_path, HTLC_HDR_FILE_PUT);

  # Add upload resume magic
  $data .= HTXF_RESUME_MAGIC;

  # Set new length: old length plus the length of HTXF_RESUME_MAGIC
  $length    = (unpack("N", substr($data, 16, 4)) + length(HTXF_RESUME_MAGIC));
  substr($data, 16, 4) = pack("N", $length);
  substr($data, 12, 4) = pack("N", $length);

  # Set new num atoms: old num atoms + 1
  $num_atoms = (unpack("n", substr($data, 20, 2)) + 1);
  substr($data, 20, 2) = pack("n", $num_atoms);

  # Fork lengths
  $data_len = (stat($src_path))[7];
  $rsrc_len = 0;

  # Mac OS specific information: resource fork length and finder comments
  if($self->{'MACOS'})
  {
    my($fsspec, $finder_comments, $res_fd, $rsrc_fh, $cat, $finfo);

    $fsspec = MacPerl::MakeFSSpec($src_path);

    # Get finder comments
    unless(defined($comments))
    {
      $finder_comments = Mac::MoreFiles::FSpDTGetComment($fsspec);
      $comments = $finder_comments  if(length($finder_comments));
    }

    $cat   = Mac::Files::FSpGetCatInfo($fsspec);
    $finfo = $cat->ioFlFndrInfo();

    # Get finder flags, type, and creator
    $finder_flags = $finfo->fdFlags();
    $type         = $finfo->fdType();
    $creator      = $finfo->fdCreator();

    # Protect from compile-time errors on non-Mac OS systems that don't
    # define O_RSRC in Fcntl
    eval '$res_fd = POSIX::open($src_path, O_RDONLY | O_RSRC)';

    $rsrc_fh = new IO::File;

    unless($rsrc_fh->fdopen($res_fd, "r"))
    {
      $self->{'LAST_ERROR'} = "Couldn't open Mac resource fork: $@";
      return;    
    }

    $rsrc_fh->seek(0, SEEK_END);    # Fast forward to end
    $rsrc_len = $rsrc_fh->tell();   # Get size
    $rsrc_fh->seek(0, SEEK_SET);    # Rewind
  }
  else
  {
    ($type, $creator) = ("BINA", "????");
  }

  # Total length of the upload to come: 111 bytes for type/creator/etc.
  # + 1 byte for the file name length + the file name + 2 bytes for the
  # comments length + the comments + 2 fork headers + the size of the
  # file to be uploaded (size of data fork plus size of resource fork).
  $length = (SIZEOF_HL_FILE_UPLOAD_HDR + 1 + length($src_file) + 2 +
             length($comments) + (2 * SIZEOF_HL_FILE_FORK_HDR) +
             $data_len + $rsrc_len);

  _debug(_hexdump($data));

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: PUT FILE - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Net::Hotline::Task($task_num, HTLC_TASK_FILE_PUT, time(), undef,
                             [ $src_path, $dest_path ],
                             [ $data_len, $rsrc_len, $comments, $finder_flags,
                               $type, $creator, $length ]);
    return($task_num);
  }
  else { return }
}

sub al08_get_file
{
  my($self, $path) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_al07_get_file_now($path); 
  }
  else
  {
    return $self->_get_file($path); 
  }
}

sub _al07_get_file_now
{
  my($self, $path) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->_get_file($path);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  if(wantarray)
  {
    return(($task, $packet->{'HTXF_REF'},  $packet->{'HTXF_SIZE'}));
  }
  else
  {
    return [ $task, $packet->{'HTXF_REF'},  $packet->{'HTXF_SIZE'} ];
  }
}

sub _get_file
{
  my($self, $path) = @_;

  my($local_sep, $remote_sep, $dest_dir, $task_num, $data_file, $rsrc_file);

  $local_sep  = PATH_SEPARATOR;
  $remote_sep = $self->{'PATH_SEPARATOR'};

  $dest_dir = $self->{'DOWNLOADS_DIR'};
  $dest_dir .= $local_sep  if($dest_dir =~ /\S/ && $dest_dir !~ /$local_sep$/o);

  ($data_file = $path) =~ s/.*?$remote_sep([^$remote_sep]+)$/$1/;

  if($self->{'MACOS'})
  {
    $rsrc_file = undef;
  }
  else
  {
    $rsrc_file = "$data_file$self->{'RSRC_FORK_EXT'}";
    $data_file = "$data_file$self->{'DATA_FORK_EXT'}";
  }

  $task_num = _file_action_simple($self, $path, HTLC_HDR_FILE_GET, HTLC_TASK_FILE_GET, 'GET FILE');

  return  unless(defined($task_num));

  $self->{'TASKS'}->{$task_num}->path([ $path, $data_file, $rsrc_file ]);

  return($task_num);
}

sub get_file_resume
{
  my($self, $path) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_al02_get_file_resume_now($path); 
  }
  else
  {
    return $self->_al08_get_file_resume($path); 
  }
}

sub _al02_get_file_resume_now
{
  my($self, $path) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->_al08_get_file_resume($path);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  if(wantarray)
  {
    return(($task, $packet->{'HTXF_REF'},  $packet->{'HTXF_SIZE'}));
  }
  else
  {
    return [ $task, $packet->{'HTXF_REF'},  $packet->{'HTXF_SIZE'} ];
  }
}

sub _al08_get_file_resume
{
  my($self, $path) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  croak("Not connected.")  unless($server->opened());

  my($local_sep, $remote_sep, $dest_dir, $data, $more_data, $task_num,
     $length, $data_file, $data_pos, $rsrc_file, $rsrc_pos);

  $local_sep  = PATH_SEPARATOR;
  $remote_sep = $self->{'PATH_SEPARATOR'};

  $dest_dir = $self->{'DOWNLOADS_DIR'};
  $dest_dir .= $local_sep  if($dest_dir =~ /\S/ && $dest_dir !~ /$local_sep$/o);

  ($data, $task_num) = _al09_file_action_stub($self, $path, HTLC_HDR_FILE_GET);

  $data_file = $path;
  
  if($data_file =~ /$remote_sep([^$remote_sep]+)$/)
  {
    $data_file = "$dest_dir$1";
  }
  else
  {
    $data_file = "$dest_dir$data_file";
  }

  if($self->{'MACOS'})
  {
    $rsrc_file = undef;
  }
  else
  {
    $rsrc_file = "$data_file$self->{'RSRC_FORK_EXT'}";
    $data_file = "$data_file$self->{'DATA_FORK_EXT'}";
  }

  unless(-e $data_file || -e $rsrc_file)
  {
    $self->{'LAST_ERROR'} = "Can't resume download: partial download does not exist.";
    return;
  }

  # Get data fork position
  $data_pos = (stat($data_file))[7];

  # Get resource fork position
  if($self->{'MACOS'})
  {
    my($res_fd, $rsrc_fh);

    # Protect from compile-time errors on non-Mac OS systems that don't
    # define O_RSRC in Fcntl
    eval '$res_fd = POSIX::open($data_file, O_RDONLY | O_RSRC)';

    $rsrc_fh = new IO::File;

    unless($rsrc_fh->fdopen($res_fd, "r"))
    {
      $self->{'LAST_ERROR'} = "Couldn't open Mac resource fork: $@";
      return;    
    }

    $rsrc_fh->seek(0, SEEK_END);    # Fast forward to end
    $rsrc_pos = $rsrc_fh->tell();   # Get size
    $rsrc_fh->seek(0, SEEK_SET);    # Rewind
  }
  else
  {
    $rsrc_pos = (stat($rsrc_file))[7];
  }

  $length = unpack("N", substr($data, 16, 4));
  $length += 78;

  # Set new length
  substr($data, 12, 4)  = pack("N", $length);
  substr($data, 16, 4) = pack("N", $length);

  # Set new num atoms
  my($num_atoms) = unpack("n", substr($data, 20, 2));
  substr($data, 20, 2) = pack("n", $num_atoms + 1);

  # 00 CB 00 4A  52 46 4C 54  00 01 00 00  00 00 00 00  ...JRFLT........
  # 00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
  # 00 00 00 00  00 00 00 00  00 00 00 00  00 02 44 41  ..............DA
  # 54 41 00 00  1B EA 00 00  00 00 00 00  00 00 4D 41  TA............MA
  # 43 52 00 00  00 00 00 00  00 00 00 00  00 00        CR............
  $more_data = pack("x78");

  substr($more_data, 0, 2) = pack("n", HTLC_DATA_RFLT);
  substr($more_data, 2, 2) = pack("n", 0x004A);
  substr($more_data, 4, 4) = HTXF_RFLT_MAGIC;
  substr($more_data, 8, 2) = pack("n", 0x0001);

  substr($more_data, 45, 1) = pack("C", 0x02);
  substr($more_data, 46, 4) = 'DATA';
  substr($more_data, 50, 4) = pack("N", $data_pos);

  substr($more_data, 62, 4) = 'MACR';
  substr($more_data, 66, 4) = pack("N", $rsrc_pos);

  $data .= $more_data;

  _debug(_hexdump($data));

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: GET FILE - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Net::Hotline::Task($task_num, HTLC_TASK_FILE_GET, time(), undef, 
                             [ $path, $data_file, $rsrc_file ]);
    return($task_num);
  }
  else { return }
}

sub _al09_file_action_stub
{
  my($self, $path, $type) = @_;

  my($data, @path_parts, $length, $file, $dir_len);

  $path =~ s/^$self->{'PATH_SEPARATOR'}//;
  $path =~ s/$self->{'PATH_SEPARATOR'}$//;
  @path_parts = split($self->{'PATH_SEPARATOR'}, $path);
  $path =~ s/$self->{'PATH_SEPARATOR'}//g;

  if(length($path) > HTLC_MAX_PATHLEN)
  {
    croak("Maximum path length exceeded");
  }

  $file = pop(@path_parts);

  # File part: 2 bytes num atoms, 2 bytes for atom len,
  # 2 bytes for file name length
  $length = (2 + 2 + 2 + length($file));

  if(@path_parts)
  {
    $dir_len = length(join('', @path_parts));
    # Path part: 2 bytes for atom type, 2 bytes for atom len
    # 2 bytes for num path components, and 2 null bytes and
    # 1 byte path part length for each path part
    $length += (2 + 2 + 2 + (3 * @path_parts));
    $length += $dir_len;
  }

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type($type);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len($length);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header();

  $data .= pack("n3a*", @path_parts ? 2 : 1,  # Number of atoms
                        HTLC_DATA_FILE,       # Atom type
                        length($file),        # Atom length
                        $file);               # Atom data

  if(@path_parts)
  {
    $data .= pack("n3", HTLC_DATA_DIRECTORY,  # Atom type
                        $dir_len + 2 + (3 * scalar(@path_parts)),
                                              # Atom length
                        scalar(@path_parts)); # Num path parts

    my($path_part);

    foreach $path_part (@path_parts)          # Path parts data
    {
      if(length($path_part) > HTLC_MAX_PATHLEN)
      {
        croak("Maximum path part length exceeded");
      }

      $data .= pack("nCa*", 0x0000,            # 2 null bytes
                            length($path_part),# Length
                            $path_part);       # Path part
    }
  }

  return($data, $proto_header->seq());
}

sub _file_action_simple
{
  my($self, $path, $type, $task_type, $task_name) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened() && length($path));

  my($data, $task_num) = _al09_file_action_stub($self, $path, $type);

  _debug(_hexdump($data));

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: $task_name - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Net::Hotline::Task($task_num, $task_type, time(), undef, $path);
    return($task_num);
  }
  else { return }
}

sub move
{
  my($self, $src_path, $dest_path) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_move_now($src_path, $dest_path); 
  }
  else
  {
    return $self->_move($src_path, $dest_path);
  }
}

sub _move_now
{
  my($self, $src_path, $dest_path) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->_move($src_path, $dest_path);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return(1);
}

sub _move
{
  my($self, $src_path, $dest_path) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened() && length($src_path)  && length($dest_path));

  my($data, $task_num, $length, $num_atoms);
  my(@src_path_parts, $save_src_path, $src_file, $src_dir_len);
  my(@dest_path_parts, $save_dest_path, $dest_dir_len);

  # Source:

  $src_path =~ s/^$self->{'PATH_SEPARATOR'}//;
  $src_path =~ s/$self->{'PATH_SEPARATOR'}$//;
  $save_src_path = $src_path;
  @src_path_parts = split($self->{'PATH_SEPARATOR'}, $src_path);
  $src_path =~ s/$self->{'PATH_SEPARATOR'}//g;

  if(length($src_path) > HTLC_MAX_PATHLEN)
  {
    croak("Maximum path length exceeded");
  }

  $src_file = pop(@src_path_parts);

  # Source part: 2 bytes num atoms, 2 bytes for atom type,
  # 2 bytes for file name length
  $length = (2 + 2 + 2 + length($src_file));

  if(@src_path_parts)
  {
    $src_dir_len = length(join('', @src_path_parts));
    # Path part: 2 bytes for atom type, 2 bytes for atom len
    # 2 bytes for num path components, and 2 null bytes and
    # 1 byte path part length for each path part
    $length += (2 + 2 + 2 + (3 * @src_path_parts));
    $length += $src_dir_len;
  }

  # Destination:

  $dest_path =~ s/^$self->{'PATH_SEPARATOR'}//;
  $dest_path =~ s/$self->{'PATH_SEPARATOR'}$//;
  $save_dest_path = $dest_path;
  @dest_path_parts = split($self->{'PATH_SEPARATOR'}, $dest_path);
  $dest_path =~ s/$self->{'PATH_SEPARATOR'}//g;

  if(length($dest_path) > HTLC_MAX_PATHLEN)
  {
    croak("Maximum path length exceeded");
  }

  if(@dest_path_parts)
  {
    $dest_dir_len = length(join('', @dest_path_parts));
    # Path part: 2 bytes for atom type, 2 bytes for atom len
    # 2 bytes for num path components, and 2 null bytes and
    # 1 byte path part length for each path part
    $length += (2 + 2 + 2 + (3 * @dest_path_parts));
    $length += $dest_dir_len;
  }

  # Build packet

  if(@src_path_parts && @dest_path_parts) { $num_atoms = 3 }
  else                                    { $num_atoms = 2 }

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_FILE_MOVE);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len($length);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header();

  $data .= pack("n3a*", $num_atoms,           # Number of atoms
                        HTLC_DATA_FILE,       # Atom type
                        length($src_file),    # Atom length
                        $src_file);           # Atom data

  if(@src_path_parts)
  {
    $data .= pack("n3", HTLC_DATA_DIRECTORY,  # Atom type
                        $src_dir_len + 2 + (3 * scalar(@src_path_parts)),
                                              # Atom length
                        scalar(@src_path_parts));
                                              # Num path parts

    my($path_part);

    foreach $path_part (@src_path_parts)      # Path parts data
    {
      if(length($path_part) > HTLC_MAX_PATHLEN)
      {
        croak("Maximum path part length exceeded");
      }

      $data .= pack("nCa*", 0x0000,           # 2 null bytes
                            length $path_part,# Length
                            $path_part);      # Path part
    }
  }

  if(@dest_path_parts)
  {
    $data .= pack("n3", HTLC_DATA_DESTDIR,    # Atom type
                        $dest_dir_len + 2 + (3 * scalar(@dest_path_parts)),
                                              # Atom length
                        scalar(@dest_path_parts));
                                              # Num path parts

    my($path_part);

    foreach $path_part (@dest_path_parts)     # Path parts data
    {
      if(length($path_part) > HTLC_MAX_PATHLEN)
      {
        croak("Maximum path part length exceeded");
      }

      $data .= pack("nCa*", 0x0000,           # 2 null bytes
                            length $path_part,# Length
                            $path_part);      # Path part
    }
  }

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: MOVE FILE - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Net::Hotline::Task($task_num, HTLC_TASK_FILE_MOVE, time(),
                         undef, [ $save_src_path, $save_dest_path ]);
    return($task_num);
  }
  else { return }
}

sub rename
{
  my($self, $path, $new_name) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_rename_now($path, $new_name); 
  }
  else
  {
    return $self->_rename($path, $new_name); 
  }
}

sub _rename_now
{
  my($self, $path, $new_name) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->rename($path, $new_name);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return(1);
}

sub _rename
{
  my($self, $path, $new_name) = @_;

  return undef  unless(length($path) && length($new_name));
  return _change_file_info($self, $path, $new_name, undef);
}

sub comment
{
  my($self, $path, $comments) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_al13_comment_now($path, $comments); 
  }
  else
  {
    return $self->_comment($path, $comments); 
  }
}

sub _al13_comment_now
{
  my($self, $path, $comments) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->comment($path, $comments);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return(1);
}

sub _comment
{
  my($self, $path, $comments) = @_;

  return undef  unless(length($path));
  $comments = ""  unless(defined($comments));
  return _change_file_info($self, $path, undef, $comments);
}

sub _change_file_info
{
  my($self, $path, $name, $comments) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  my($data, $task_num, @path_parts, $length, $save_path, $file,
     $dir_len, $num_atoms);

  $path =~ s/^$self->{'PATH_SEPARATOR'}//;
  $path =~ s/$self->{'PATH_SEPARATOR'}$//;
  $save_path = $path;
  @path_parts = split($self->{'PATH_SEPARATOR'}, $path);
  $path =~ s/$self->{'PATH_SEPARATOR'}//g;

  if(length($path) > HTLC_MAX_PATHLEN)
  {
    croak("Maximum path length exceeded");
  }

  $file = pop(@path_parts);

  # File part: 2 bytes for num atoms, 2 bytes for atom type,
  # 2 bytes for file name length
  $length = (2 + 2 + 2 + length($file));

  if(@path_parts)
  {
    $dir_len = length(join('', @path_parts));
    # Path part: 2 bytes for atom type, 2 bytes for atom len
    # 2 bytes for num path components, and 2 null bytes and
    # 1 byte path part length for each path part
    $length += (2 + 2 + 2 + (3 * @path_parts));
    $length += $dir_len;
  }

  if(length($name))
  {
    # Name part: 2 bytes for atom type, 2 bytes for
    # atom len, and the new name
    $length += (2 + 2 + length($name));
  }

  if(defined($comments))
  {
    # Comments part: 2 bytes for atom type, 2 bytes for
    # atom len, length of the new comments, else 1 null
    # byte if removing comments.
    $length += 2 + 2;
    if(length($comments)) { $length += length($comments) }
    else                  { $length += 1                 }
  }

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_FILE_SETINFO);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len($length);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header();

  $num_atoms = (@path_parts) ? 2 : 1;
  $num_atoms++  if(length($name));
  $num_atoms++  if(defined($comments));

  $data .= pack("n3a*", $num_atoms,           # Number of atoms
                        HTLC_DATA_FILE,       # Atom type
                        length($file),        # Atom length
                        $file);               # Atom data

  if(@path_parts)
  {
    $data .= pack("n3", HTLC_DATA_DIRECTORY,  # Atom type
                        $dir_len + 2 + (3 * scalar(@path_parts)),
                                              # Atom length
                        scalar(@path_parts)); # Num path parts

    my($path_part);

    foreach $path_part (@path_parts)          # Path parts data
    {
      if(length($path_part) > HTLC_MAX_PATHLEN)
      {
        croak("Maximum path part length exceeded");
      }

      $data .= pack("nCa*", 0x0000,           # 2 null bytes
                            length $path_part,# Length
                            $path_part);      # Path part
    }
  }

  if(length($name))
  {
    $data .= pack("nna*", HTLC_DATA_FILE_RENAME,# Atom type
                          length($name),      # Length
                          $name);             # Name
  }

  if(defined($comments))
  {
    $data .= pack("n", HTLS_DATA_FILE_COMMENT);# Atom type

    if(length($comments))
    {
      $data .= pack("na*", length($comments), # Length
                           $comments);        # Comments
    }
    else # Remove comments
    {
      $data .=  pack("nx", 0x0001);           # Length + null byte
    }
  }

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: SET INFO - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Net::Hotline::Task($task_num, HTLC_TASK_SET_INFO, time(), undef, $save_path);
    return($task_num);
  }
  else { return }
}

sub post_news
{
  my($self, @post) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_al10_post_news_now(@post); 
  }
  else
  {
    return $self->_post_news(@post); 
  }
}

sub _al10_post_news_now
{
  my($self, @post) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->post_news(@post);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return(1);
}

sub _post_news
{
  my($self, @post) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  my($post) = join('', @post);

  my($data, $task_num);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_NEWS_POST);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_SHORT_HDR + length($post));
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n3a*", 0x0001,                # Number of atoms
                       HTLS_DATA_NEWS_POST,   # Atom type
                       length($post),         # Atom length
                       $post);                # Atom data

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: POST NEWS - $task_num\n");
    $self->{'TASKS'}->{$task_num} =
      new Net::Hotline::Task($task_num, HTLC_TASK_NEWS_POST, time());
  }
  else { return }

  return($task_num);
}

sub get_news
{
  my($self) = shift;

  my($task, $task_num, $packet);

  $task_num = $self->req_news();
  $task = $self->{'TASKS'}->{$task_num};

  return(undef)  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return(undef);
  }

  if(wantarray)
  {
    return @{$self->{'NEWS'}};
  }
  else
  {
    return (@{$self->{'NEWS'}}) ? join('_' x 58, @{$self->{'NEWS'}}) : "";
  }
}

sub req_news
{
  my($self) = shift;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  my($data, $task_num);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_NEWS_GETFILE);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_TASK_FILLER);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n", 0x0000);

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: NEWS - $task_num\n");
    $self->{'TASKS'}->{$task_num} = 
      new Net::Hotline::Task($task_num, HTLC_TASK_NEWS, time());
    return($task_num);
  }
  else { return }
}

sub al04_user_by_nick
{
  my($self, $nick_match) = @_;

  my($socket, @users);

  eval { m/$nick_match/ };

  return undef  if($@ || !$self->{'USER_LIST'} || length($nick_match) == 0);

  foreach $socket (sort { $a <=> $b } keys(%{$self->{'USER_LIST'}}))
  {
    if($self->{'USER_LIST'}->{$socket}->nick() =~ /^$nick_match$/)
    {
      if(wantarray())
      {
        push(@users, $self->{'USER_LIST'}->{$socket});
      }
      else
      {
        return $self->{'USER_LIST'}->{$socket};
      }
    }
  }

  if(@users) { return @users }
  else       { return }
}

sub user_by_socket
{
  my($self, $socket) = @_;
  return $self->{'USER_LIST'}->{$socket};
}

sub icon
{
  my($self, $icon) = @_;

  return $self->{'ICON'}  unless($icon =~ /^-?\d+$/);

  return _update_user($self, $icon, $self->{'NICK'});
}

sub nick
{
  my($self, $nick) = @_;

  return $self->{'NICK'}  unless(defined($nick));

  return _update_user($self, $self->{'ICON'}, $nick);
}

sub _update_user
{
  my($self, $icon, $nick) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  my($data);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_USER_CHANGE);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len((SIZEOF_HL_SHORT_HDR * 2) + length($nick));
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n6a*", 0x0002,                # Num atoms

                       HTLC_DATA_ICON,        # Atom type
                       0x0002,                # Atom length
                       $icon,                 # Atom data

                       HTLC_DATA_NICKNAME,    # Atom type
                       length($nick),         # Atom length
                       $nick);                # Atom data

  $self->{'NICK'} = $nick;
  $self->{'ICON'} = $icon;

  _debug(_hexdump($data));

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    return(1);
  }
  else { return }
}

sub get_userlist
{
  my($self) = shift;

  my($task, $task_num, $packet);

  $task_num = $self->req_userlist();
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return $self->{'USER_LIST'};
}

sub al05_req_userlist
{
  my($self) = shift;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  my($data, $task_num);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_USER_GETLIST);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_TASK_FILLER);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n", 0x0000);

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: GET USER LIST - $task_num\n");
    $self->{'TASKS'}->{$task_num} =
      new Net::Hotline::Task($task_num, HTLC_TASK_USER_LIST, time());
    return($task_num);
  }
  else { return }
}

sub kick
{
  my($self, $user_or_socket) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_kick_now($user_or_socket); 
  }
  else
  {
    return $self->_kick($user_or_socket); 
  }
}

sub _kick_now
{
  my($self, $user_or_socket) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->_kick($user_or_socket);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return(1);
}

sub _kick
{
  my($self, $user_or_socket) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  my($socket, $task_num);

  if(ref($user_or_socket)) { $socket = $user_or_socket->socket() }
  else                     { $socket = $user_or_socket           }

  my($data);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_USER_KICK);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_LONG_HDR);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n4", 0x0001,                  # Num atoms

                     HTLC_DATA_SOCKET,        # Atom type
                     0x0002,                  # Atom length
                     $socket);                # Atom data

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: KICK($socket) - $task_num\n");
    $self->{'TASKS'}->{$task_num} =
      new Net::Hotline::Task($task_num, HTLC_TASK_KICK, time());
  }
  else { return }

  return ($task_num);
}

sub ban
{
  my($self, $user_or_socket) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_ban_now($user_or_socket); 
  }
  else
  {
    return $self->_ban($user_or_socket); 
  }
}

sub _ban_now
{
  my($self, $user_or_socket) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->_ban($user_or_socket);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return(1);
}

sub _ban
{
  my($self, $user_or_socket) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  my($socket, $task_num);

  if(ref($user_or_socket)) { $socket = $user_or_socket->socket() }
  else                     { $socket = $user_or_socket           }

  my($data);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_USER_KICK);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_LONG_HDR + 6);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n7", 0x0002,                  # Num atoms

                     HTLC_DATA_SOCKET,        # Atom type
                     0x0002,                  # Atom length
                     $socket,                 # Atom data

                     HTLC_DATA_BAN,           # Atom type
                     0x0002,                  # Atom length
                     0x0001);                 # Atom data (always 1???)

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: BAN($socket) - $task_num\n");
    $self->{'TASKS'}->{$task_num} =
      new Net::Hotline::Task($task_num, HTLC_TASK_BAN, time());
  }
  else { return }
  
  return ($task_num);
}

sub msg
{
  my($self, $user_or_socket, @message) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_msg_now($user_or_socket, @message); 
  }
  else
  {
    return $self->_msg($user_or_socket, @message); 
  }
}

sub _msg_now
{
  my($self, $user_or_socket, @message) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->_msg($user_or_socket, @message);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return(1);
}

sub _msg
{
  my($self, $user_or_socket, @message) = @_;

  my($message) = join('', @message);

  $message =~ s/\n/@{[HTLC_NEWLINE]}/osg;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  my($socket);

  if(ref($user_or_socket)) { $socket = $user_or_socket->socket() }
  else                     { $socket = $user_or_socket           }

  my($data, $task_num);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_MSG);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len((SIZEOF_HL_SHORT_HDR * 2) +
                     length($message));
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n6", 0x0002,                  # Num atoms

                     HTLC_DATA_SOCKET,        # Atom type
                     0x0002,                  # Atom length
                     $socket,                 # Atom data

                     HTLC_DATA_MSG,           # Atom type
                     length($message)) .      # Atom length
          $message;                           # Atom data

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: MSG - $task_num\n");
    $self->{'TASKS'}->{$task_num} =
      new Net::Hotline::Task($task_num, HTLC_TASK_SEND_MSG, time());
  }
  else { return }

  return($task_num);
}

sub chat_action
{
  my($self, @message) = @_;

  my($message) = join('', @message);

  $message =~ s/\n/@{[HTLC_NEWLINE]}/osg;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  my($data);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_CHAT);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len((SIZEOF_HL_SHORT_HDR  * 2) +
                     length($message));
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n6", 0x0002,                  # Num atoms

                     HTLC_DATA_OPTION,        # Atom type
                     0x0002,                  # Atom length
                     0x0001,                  # Atom data

                     HTLC_DATA_CHAT,          # Atom type
                     length($message)) .      # Atom length
          $message;                           # Atom data

  _debug(_hexdump($data));

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    return(1);
  }
  else { return }
}

sub chat
{
  my($self, @message) = @_;

  my($message) = join('', @message);

  $message =~ s/\n/@{[HTLC_NEWLINE]}/osg;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  my($data);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_CHAT);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(SIZEOF_HL_SHORT_HDR +
                     length($message));
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header() .
          pack("n3", 0x0001,                  # Num atoms

                     HTLC_DATA_CHAT,          # Atom type
                     length($message)) .      # Atom length
          $message;                           # Atom data

  _debug(_hexdump($data));

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    return(1);
  }
  else { return }
}

sub send_file
{
  my($self, $task, $ref, $size, $resume) = @_;

  my($server, $port, $data, $xfer, $length, $buf_size);
  my($local_sep, $remote_sep, $filename, $src_path, $dest_path);
  my($type, $creator, $created, $modified, $finder_flags,  $comments,
     $data_fh, $rsrc_fh, $data_len, $rsrc_len, $data_pos, $rsrc_pos,
     $res_fd);

  $task->finish(undef);

  $local_sep = PATH_SEPARATOR;

  $buf_size = $self->{'HTXF_BUFSIZE'};

  if($resume)
  {
    # 52 46 4c 54  00 01 00 00  00 00 00 00  00 00 00 00  RFLT............
    # 00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
    # 00 00 00 00  00 00 00 00  00 02 44 41  54 41 00 06  ..........DATA..
    # 9a cf 00 00  00 00 00 00  00 00 4d 41  43 52 00 00  ..........MACR..
    # 00 00 00 00  00 00 00 00  00 00                     ..........

    unless(substr($resume, 0, 4) eq 'RFLT')
    {
      $task->error(1);
      $task->finish(time());
      $task->error_text("Bad data from server!");
      $self->{'LAST_ERROR'} = $task->error_text();
      return;
    }

    $data_pos = unpack("N", substr($resume, 46, 4));
    $rsrc_pos = unpack("N", substr($resume, 62, 4));
  }

  $data_fh = new IO::File;
  $rsrc_fh = new IO::File;

  ($src_path, $dest_path) = @{$task->path()};

  ($filename = $src_path) =~ s/^.*?$local_sep([^$local_sep]+)$/$1/;

  ($data_len, $rsrc_len, $comments, $finder_flags, $type, $creator, $length)
    = @{$task->misc()};

  unless($data_fh->open($src_path))
  {
    $task->error(1);
    $task->finish(time());
    $task->error_text("Could not open to $src_path: $!");
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  if($self->{'MACOS'})
  {
    # Protect from compile-time errors on non-Mac OS systems that don't
    # define O_RSRC in Fcntl
    eval '$res_fd = POSIX::open($src_path, O_RDONLY | O_RSRC)';

    unless($rsrc_fh->fdopen($res_fd, "r"))
    {
      $task->error(1);
      $task->finish(time());
      $task->error_text("Could not read to resource fork from $src_path: $!");
      $self->{'LAST_ERROR'} = $task->error_text();
      return;
    }
  }
  elsif($rsrc_len > 0 || ($resume && $rsrc_pos > 0))
  {
    $task->error(1);
    $task->finish(time());
    $task->error_text("Server is expecting resource fork data from a non-Mac OS client!\n" .
                      "Are you sure you're uploading the right file?");
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  if($resume)
  {
    if($rsrc_pos > 0)
    {
      unless($rsrc_fh->seek($rsrc_pos, 0))
      {
        $task->error(1);
        $task->finish(time());
        $task->error_text("Could not seek to position $rsrc_pos in resource fork of $src_path: $!");
        $self->{'LAST_ERROR'} = $task->error_text();
        return;
      }
    }

    if($data_pos > 0)
    {
      unless($data_fh->seek($data_pos, 0))
      {
        $task->error(1);
        $task->finish(time());
        $task->error_text("Could not seek to position $data_pos in $src_path: $!");
        $self->{'LAST_ERROR'} = $task->error_text();
        return;
      }
    }
  }

  ($created, $modified) = (stat($src_path))[9,10];

  unless($self->{'MACOS'})
  {
    $created  += HTLC_UNIX_TO_MACOS_TIME;
    $modified += HTLC_UNIX_TO_MACOS_TIME;
  }

  $data = HTXF_MAGIC . pack("NNx4", $ref, ($length - $rsrc_pos - $data_pos));

  $server = $self->{'SERVER_ADDR'};

  # HTXF_TCPPORT only if server port is 5500
  $port = $self->{'SERVER_PORT'} + 1; 

  unless($xfer = IO::Socket::INET->new(PeerAddr =>$server,
                                       PeerPort =>$port,
                                       Timeout  =>$self->{'CONNECT_TIMEOUT'},
                                       Proto    =>'tcp'))
  {
    $task->finish(time());
    $task->error_text("Could not open file transfer connection: $@");
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  _debug(_hexdump($data));

  unless(_hlc_write($self, $xfer, \$data, length($data)))
  {
    $xfer->close();
    $task->error(1);
    $task->finish(time());
    $task->error_text($self->{'LAST_ERROR'});
    return;
  }

  # 46 49 4c 50  00 01 00 00  00 00 00 00  00 00 00 00  FILP............
  # 00 00 00 00  00 00 00 03  49 4e 46 4f  00 00 00 00  ........INFO....
  # 00 00 00 00  00 00 00 5c  41 4d 41 43  53 49 54 44  .......\AMACSITD
  # 53 49 54 21  00 00 00 00  00 00 21 00  00 00 00 00  SIT!......!.....
  # 00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
  # 00 00 00 00  00 00 00 00  00 00 00 00  00 07 70 00  ..............p.
  # 00 b1 ce 81  92 07 70 00  00 02 df 7d  3d 00 00 00  ......p....}=...

  # 12 53 77 6f  6f 70 20 46  41 51 2e 74  65 78 74 2e  .Swoop FAQ.text.
  # 73 69 74 00  00 44 41 54  41 00 00 00  00 00 00 00  sit..DATA.......
  # 00 00 00 59  5c                                     ...Y\
  $data = pack("a4nx16na4x8Na4a4a4x6nx32nx2Nnx2NN",
               "FILP", 0x0001, 0x0003, "INFO",
               length($comments) + length($filename) + 74,
               "AMAC", $type, $creator, $finder_flags, 0x0770,
               $created, 0x0770, $modified, length($filename));

  $data .= $filename .
           pack("n", length($comments)) .
           $comments .
           pack("a4x8N", "DATA", ($data_len - $data_pos));

  _debug(_hexdump($data));

  unless(_hlc_write($self, $xfer, \$data, length($data)))
  {
    $xfer->close();
    $task->error(1);
    $task->finish(time());
    $task->error_text($self->{'LAST_ERROR'});
    return;
  }

  # Upload data fork
  unless($self->_upload($xfer, $data_fh, $data_len, $buf_size))
  {
    $xfer->close();
    $task->error(1);
    $task->finish(time());
    $task->error_text("Upload did not complete.");
  }

  # 4D 41 43 52  00 00 00 00  00 00 00 00  00 00 01 EC  MACR............
  $data = pack("a4x8N", "MACR", ($rsrc_len - $rsrc_pos));

  _debug(_hexdump($data));

  unless(_hlc_write($self, $xfer, \$data, length($data)))
  {
    $xfer->close();
    $task->error(1);
    $task->finish(time());
    $task->error_text($self->{'LAST_ERROR'});
    return;
  }

  if($rsrc_len > 0)
  {
    # Upload resource fork
    unless($self->_upload($xfer, $rsrc_fh, $rsrc_len, $buf_size))
    {
      $xfer->close();
      $task->error(1);
      $task->finish(time());
      $task->error_text("Upload did not complete.");
      return;
    }
  }

  return(1);
}

sub recv_file
{
  my($self, $task, $ref, $size) = @_;

  my($server, $data, $xfer, $tot_length, $length, $buf_size, @ret);
  my($data_file, $rsrc_file, $type, $creator, $created, $modified,
     $finder_flags,  $comments, $comments_len, $data_fh, $data_len,
     $rsrc_fh, $rsrc_len, $name_len, $real_mac_res_fork, $res_fd,
     $finished_file, $port);

  $tot_length = $size;

  $buf_size = $self->{'HTXF_BUFSIZE'};

  $data_fh = new IO::File;
  $rsrc_fh = new IO::File;

  ($data_file, $rsrc_file) = @{$task->path()}[1, 2];

  if($self->{'MACOS'})
  {
    if(length($data_file) > MACOS_MAX_FILENAME)
    {
      for($data_file)
      {
        my($len) = MACOS_MAX_FILENAME - 6;
        
        # Try to preserve filename extension, if any
        # ("\xC9" is "..." in Mac OS)
        # Otherwise, just truncate
        s/^(.{$len}).*?\.(\w{1,4})/$1\xC9.$2/o ||
        s/^(.@{[MACOS_MAX_FILENAME]}).*/$1/;
      }
    }
  }

  unless($data_fh->open(">>$data_file"))
  {
    $task->error(1);
    $task->finish(time());
    $task->error_text("Could not write to $data_file: $!");
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  if($self->{'MACOS'})
  {
    # Protect from compile-time errors on non-Mac OS systems that don't
    # define O_RSRC in Fcntl
    eval '$res_fd = POSIX::open($data_file, O_WRONLY | O_CREAT | O_RSRC)';
  }

  # If we're on Mac OS and we can write directly to the resource fork
  if(defined($res_fd) && $rsrc_fh->fdopen($res_fd, "w"))
  {
    $real_mac_res_fork = 1;
    # Temporarily set file type and creator to Hotline's "partial download"
    MacPerl::SetFileInfo(HTXF_PARTIAL_CREATOR, HTXF_PARTIAL_TYPE, $data_file);
  }
  else
  {
    unless($rsrc_fh->open(">>$rsrc_file"))
    {
      $task->error(1);
      $task->finish(time());
      $task->error_text("Could not write to $rsrc_file: $!");
      $self->{'LAST_ERROR'} = $task->error_text();
      return;
    }
  }

  $task->finish(undef);

  $server = $self->{'SERVER_ADDR'};

  $data = HTXF_MAGIC . pack("Nx8", $ref);

  # HTXF_TCPPORT only if server port is 5500
  $port = $self->{'SERVER_PORT'} + 1; 

  unless($xfer = IO::Socket::INET->new(PeerAddr =>$server,
                                       PeerPort =>$port,
                                       Timeout  =>$self->{'CONNECT_TIMEOUT'},
                                       Proto    =>'tcp'))
  {
    $task->finish(time());
    $task->error_text("Could not open file transfer connection: $@");
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  unless(_hlc_write($self, $xfer, \$data, length($data)))
  {
    $xfer->close();
    $task->error(1);
    $task->finish(time());
    $task->error_text($self->{'LAST_ERROR'});
    return;
  }

  # 46 49 4C 50  00 01 00 00  00 00 00 00  00 00 00 00  FILP............
  # 00 00 00 00  00 00 00 03  49 4E 46 4F  00 00 00 00  ........INFO....
  # 00 00 00 00  00 00 00 60                            .......`
  unless(_hlc_buffered_read($self, $xfer, \$data, SIZEOF_HL_FILE_XFER_HDR))
  {
    $xfer->close();
    $task->error(1);
    $task->finish(time());
    $task->error_text($self->{'LAST_ERROR'});
    return;
  }

  $tot_length -= SIZEOF_HL_FILE_XFER_HDR;
  $length = (unpack("N", substr($data, 36, 4)) + SIZEOF_HL_FILE_FORK_HDR);

  unless(substr($data, 0, 4) eq 'FILP')
  {
    $xfer->close();
    $task->error(1);
    $task->finish(time());
    $task->error_text("Bad data from server!");
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  #                           41 4D 41 43  54 45 58 54          AMACTEXT
  # 74 74 78 74  00 00 00 00  00 00 01 00  00 00 00 00  ttxt............
  # 00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
  # 00 00 00 00  00 00 00 00  00 00 00 00  07 70 00 00  .............p..
  # AE A3 8A 18  07 70 00 00  AE A3 8C 1D  00 00 00 05  .....p..........
  # 74 65 78 74  32 00 11 66  74 70 2E 6D  69 63 72 6F  text2..ftp.micro
  # 73 6F 66 74  2E 63 6F 6D  44 41 54 41  00 00 00 00  soft.comDATA....
  # 00 00 00 00  00 00 01 00                            ........

  unless(_hlc_buffered_read($self, $xfer, \$data, $length))
  {
    $xfer->close();
    $task->error(1);
    $task->finish(time());
    $task->error_text($self->{'LAST_ERROR'});
    return;
  }

  $tot_length -= $length;

  $type     = substr($data, 4, 4);
  $creator  = substr($data, 8, 4);

  $created      = unpack("N", substr($data, 56, 4));
  $finder_flags = substr($data, 18, 2);
  $modified     = unpack("N", substr($data, 64, 4));
  $name_len     = unpack("C", substr($data, 71, 1));
  $comments_len = unpack("n", substr($data, 72 + $name_len, 2)); # 72
  $comments = substr($data, 72 + $name_len + 2, $comments_len);

  $data_len = unpack("N", substr($data, -4));
  $length = $self->_download($xfer, $data_fh, $data_len, $buf_size);
  $tot_length -= $length;
  $data_fh->close();

  unless($length == $data_len)
  {
    $xfer->close();
    $task->error(1);
    $task->finish(time());
    $task->error_text("Download incomplete.");
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  # Yet another server bug: it'll tell you it's going to send a resource
  # fork header even when the file has no resource fork (i.e. $size will
  # be SIZEOF_HL_FILE_FORK_HDR bytes larger than the data the server will
  # actually send).  So we only try to read if we have more than
  # SIZEOF_HL_FILE_FORK_HDR left.
  if($tot_length > SIZEOF_HL_FILE_FORK_HDR)
  {
    # 4D 41 43 52  00 00 00 00  00 00 00 00  00 00 01 EC  MACR............
    $length = _hlc_buffered_read($self, $xfer, \$data, SIZEOF_HL_FILE_FORK_HDR);

    return  unless($length);
    $tot_length -= $length;

    $rsrc_len = unpack("N", substr($data, -4));
    $length = $self->_download($xfer, $rsrc_fh, $rsrc_len, $buf_size);
    $tot_length -= $length;
    $rsrc_fh->close();

    unless($length == $rsrc_len)
    {
      $xfer->close();
      $task->error(1);
      $task->finish(time());
      $task->error_text("Download incomplete.");
      $self->{'LAST_ERROR'} = $task->error_text();
      return;
    }
  }
  else
  {
    $tot_length = 0;
    $rsrc_len = 0;
  }

  $xfer->close();

  unless($tot_length == 0)
  {
    $task->error(1);
    $task->finish(time());
    $task->error_text("Tried to download $size bytes, got " .
                      $size - $tot_length . " bytes instead.");
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  $data_len = (stat($data_file))[7];
  $rsrc_len = (stat($rsrc_file))[7];

  unless($rsrc_len)
  {
    unlink($rsrc_file)  if(-e $rsrc_file);
    undef $rsrc_file;
    $rsrc_len = 0;
  }

  unless($data_len || $real_mac_res_fork)
  {
    unlink($data_file)  if(-e $data_file);
    undef $data_file;
    $data_len = 0;
  }

  $task->finish(time());

  # Set the rest of the Mac OS information if we're doing that sort of thing
  if(($real_mac_res_fork && -e $data_file))
  {
    utime($created, $modified, $data_file);

    my($fsspec) = MacPerl::MakeFSSpec($data_file);

    if(length($comments))
    {
      Mac::MoreFiles::FSpDTSetComment($fsspec, $comments);
    }

    my($cat)   = Mac::Files::FSpGetCatInfo($fsspec);
    my($finfo) = $cat->ioFlFndrInfo();

    $finfo->fdFlags(unpack("n", $finder_flags) & 0xFEFF);
    $finfo->fdType($type);
    $finfo->fdCreator($creator);
    $cat->ioFlFndrInfo($finfo);
    Mac::Files::FSpSetCatInfo($fsspec, $cat);

    # Rename data file to remove the .data part
    ($finished_file = $data_file) =~ s/$self->{'DATA_FORK_EXT'}$//;
    unless(CORE::rename($data_file, $finished_file))
    {
      $task->error_text(qq(Could not rename "$data_file" to "$finished_file": $!));
      $self->{'LAST_ERROR'} = $task->error_text();
      return;
    }

    # Return a sigle true value rather than an array of parameters
    # to indicate that you can't call macbinary() if we've already
    # made a Mac file.
    return(1);
  }
  elsif(! -e $rsrc_file)
  {
    ($finished_file = $data_file) =~ s/$self->{'DATA_FORK_EXT'}$//;
    CORE::rename($data_file, $finished_file);
    $data_file = $finished_file;
  }

  return [ $data_file, $data_len,
           $rsrc_file, $rsrc_len,
           $buf_size, $type, $creator, $comments,
           $created, $modified, $finder_flags ];
}

sub _download
{
  my($self, $src_fh, $dest_fh, $len, $buf_size) = @_;

  my($data, $tot_read, $read);

  $tot_read = 0;

  if($len <= $buf_size)
  {
    $read = read($src_fh, $data, $len);
    return  unless(defined($read));
    print $dest_fh $data || return;
    $tot_read += $read;
  }
  else
  {
    my($loop)     = int($len/$buf_size);
    my($leftover) = $len % $buf_size;

    for(; $loop > 0; $loop--)
    {
      $read = read($src_fh, $data, $buf_size);
      return  unless(defined($read));
      print $dest_fh $data || return;
      $tot_read += $read;
    }

    if($leftover > 0)
    {
      $read = read($src_fh, $data, $leftover);
      return  unless(defined($read));
      print $dest_fh $data || return;
      $tot_read += $read;
    }
  }

  unless($tot_read == $len)
  {
    croak("Tried to read $len bytes, actually read $tot_read.  Download may be corrupted!");
  }

  return($tot_read);
}

sub _upload
{
  my($self, $dest_fh, $src_fh, $len, $buf_size) = @_;

  my($data);

  if($len <= $buf_size)
  {
    unless(defined(read($src_fh, $data, $len))) { return }
    _hlc_write($self, $dest_fh, \$data, length($data)) || return;
  }
  else
  {
    my($loop)     = int($len/$buf_size);
    my($leftover) = $len % $buf_size;

    for(; $loop > 0; $loop--)
    {
      unless(defined(read($src_fh, $data, $buf_size))) { return }
      _hlc_write($self, $dest_fh, \$data, length($data)) || return;
    }

    if($leftover > 0)
    {
      unless(defined(read($src_fh, $data, $leftover))) { return }
      _hlc_write($self, $dest_fh, \$data, length($data)) || return;
    }
  }

  return(1);
}

sub macbinary
{
  my($self) = shift  if(ref($_[0]));

  my($macbin_file, $params) = @_;

  unless(ref($params) =~ /^ARRAY/ && @{$params} == 11)
  {
    croak("Incorrect arguments to macbinary()");
  }

  my($data_file, $data_len,
     $rsrc_file, $rsrc_len,
     $buf_size, $type, $creator, $comments,
     $created, $modified, $finder_flags) = @{$params};

  my($finished_file, $filename, $macbin_fh, $data_fh, $rsrc_fh,
     $macbin_hdr, $buf, $len, $pad);

  unless($rsrc_len > 0 || $data_len > 0)
  {
    $self->{'LAST_ERROR'} = "No resource or data fork length."  if($self);
    $! = "No resource or data fork length.";
    return;
  }

  if(defined($data_file))
  {
    ($finished_file = $data_file) =~ s/$self->{'DATA_FORK_EXT'}$//;
  }
  elsif(defined($rsrc_file))
  {
    ($finished_file = $rsrc_file) =~ s/$self->{'RSRC_FORK_EXT'}$//;
  }
  else
  {
    croak "Bad arguments to macbinary() - No rsrc or data file arguments.";
  }

  $finished_file =~ /([^@{[PATH_SEPARATOR]}]+)$/o;
  $filename = $1;

  unless(length($macbin_file))
  {
    $macbin_file .= "$finished_file.bin";
  }

  if(-e $macbin_file)
  {
    $self->{'LAST_ERROR'} = "$macbin_file: file already exists."  if($self);
    $! = "$macbin_file: file already exists.";
    return;
  }

  $buf_size = 4096  unless($buf_size =~ /^\d+$/);

  $macbin_fh = new IO::File;
  $data_fh   = new IO::File;
  $rsrc_fh   = new IO::File;

  unless($macbin_fh->open(">$macbin_file"))
  {
    $self->{'LAST_ERROR'} = $!  if($self);
    return;
  }

  $macbin_hdr = pack("x128"); # Start with empty 128 byte header

  # Offset 000-Byte, old version number, must be kept at zero for compatibility

  # Offset 001-Byte, Length of filename (must be in the range 1-63)
  substr($macbin_hdr, 1, 1) = pack("C", length($filename));

  # Offset 002-1 to 63 chars, filename (only "length" bytes are significant).
  substr($macbin_hdr, 2, length($filename)) = $filename;

  # Offset 065-Long Word, file type (normally expressed as four characters)
  substr($macbin_hdr, 65, 4) = $type;

  # Offset 069-Long Word, file creator (normally expressed as four characters)
  substr($macbin_hdr, 69, 4) = $creator;

  # Offset 073-Byte, original Finder flags
  #     Bit 7 - Locked.
  #     Bit 6 - Invisible.
  #     Bit 5 - Bundle.
  #     Bit 4 - System.
  #     Bit 3 - Bozo.
  #     Bit 2 - Busy.
  #     Bit 1 - Changed.
  #     Bit 0 - Inited.
  substr($macbin_hdr, 73, 1) =             # Clear inited bit
    pack("C", unpack("C", substr($finder_flags, 0, 1)) & 0xFE);

  # Offset 074-Byte, zero fill, must be zero for compatibility

  # Offset 075-Word, file's vertical position within its window.
  substr($macbin_hdr, 75, 2) = pack("n", 0xFFFF);

  # Offset 077-Word, file's horizontal position within its window.
  substr($macbin_hdr, 77, 2) = pack("n", 0xFFFF);

  # Offset 079-Word, file's window or folder ID.
  # Offset 081-Byte, "Protected" flag (in low order bit).
  # Offset 082-Byte, zero fill, must be zero for compatibility

  # Offset 083-Long Word, Data Fork length (bytes, zero if no Data Fork).
  substr($macbin_hdr, 83, 4) = pack("N", $data_len);

  # Offset 087-Long Word, Resource Fork length (bytes, zero if no R.F.).
  substr($macbin_hdr, 87, 4) = pack("N", $rsrc_len);

  # Offset 091-Long Word, File's creation date
  substr($macbin_hdr, 91, 4) = pack("N", $created);

  # Offset 095-Long Word, File's "last modified" date.
  substr($macbin_hdr, 95, 4) = pack("N", $modified);

  # Offset 099-Word, length of Get Info comment to be sent after the resource fork
  #            (if implemented, see below).
  # Offset 101-Byte, Finder Flags, bits 0-7. (Bits 8-15 are already in byte 73)
  # Offset 116-Long Word, Length of total files when packed files are unpacked.
  #            This is only used by programs that pack and unpack on the fly,
  #            mimicing a standalone utility such as PackIt. A program that is
  #            uploading a single file must zero this location when sending a
  #            file. Programs that do not unpack/uncompress files when
  #            downloading may ignore this value.
  substr($macbin_hdr, 116, 4) = pack("N", $data_len + $rsrc_len);

  # Offset 120-Word, Length of a secondary header. If this is non-zero,
  #            Skip this many bytes (rounded up to the next multiple of 128)
  #            This is for future expansion only, when sending files with
  #            MacBinary, this word should be zero.

  # Offset 122-Byte, Version number of Macbinary II that the uploading program
  # is written for (the version begins at 129)
  substr($macbin_hdr, 122, 1) = pack("C", 129);

  # Offset 123-Byte, Minimum MacBinary II version needed to read this file
  # (start this value at 129 129)
  substr($macbin_hdr, 123, 1) = pack("C", 129);

  # Offset 124-Word, CRC of previous 124 bytes
  substr($macbin_hdr, 124, 2) = pack("n", macbin_crc(substr($macbin_hdr, 0, 124), 0));

  # Macbinary II header
  print $macbin_fh $macbin_hdr;

  # Data fork, null padded to a multiple of 128 bytes
  if($data_len)
  {
    unless($data_fh->open($data_file))
    {
      $self->{'LAST_ERROR'} = $!  if($self);
      return;
    }

    while($len = read($data_fh, $buf, $buf_size))
    {
      croak("read() error: $!")  unless(defined($len));
      print $macbin_fh $buf;
    }
    $data_fh->close();

    if($data_len % 128)
    {
      $pad = "x" . (128 - ($data_len % 128));
      print $macbin_fh pack($pad);
    }
  }

  # Resource fork, null padded to a multiple of 128 bytes
  if($rsrc_len)
  {
    unless($rsrc_fh->open($rsrc_file))
    {
      $self->{'LAST_ERROR'} = $!  if($self);
      return;
    }

    while($len = read($rsrc_fh, $buf, $buf_size))
    {
      croak("read() error: $!")  unless(defined($len));
      print $macbin_fh $buf;      
    }
    $rsrc_fh->close();

    if($rsrc_len % 128)
    {
      $pad = "x" . (128 - ($rsrc_len % 128));
      print $macbin_fh pack($pad);
    }
  }

  $macbin_fh->close();

  return(1);
}

sub tracker
{
  $_[0]->{'TRACKER_ADDR'} = $_[1]  if(@_ == 2);
  return $_[0]->{'TRACKER_ADDR'};
}

sub tracker_list
{
  my($self, $timeout) = @_;

  my($tracker, $tracker_address, $server, $port, @servers, $data,
     $num_servers, $length, $tli_ip, $tli_port, $tli_num_users,
     $tli_name, $tli_desc, $byte1);

  $tracker_address = $self->{'TRACKER_ADDR'};

  unless($tracker_address =~ /\S/)
  {
    croak("Tracker address not set!");
  }

  if(($server = $tracker_address) =~ s/^([^ :]+)(?:[: ](\d+))?$/$1/)
  {
    $port = $2 || HTRK_TCPPORT;
  }
  else
  {
    croak("Bad server address: $tracker_address");
  }

  $timeout = $self->{'CONNECT_TIMEOUT'}  unless(defined($timeout));

  eval
  {
    $SIG{'ALRM'} = sub { die "timeout" };
    alarm($timeout);
  
    $tracker = IO::Socket::INET->new(PeerAddr =>$server,
                                     PeerPort =>$port,
                                     Timeout  =>$timeout,
                                     Proto    =>'tcp');
    alarm(0);
    $SIG{'ALRM'} = 'DEFAULT';
  };

  if($@ =~ /timeout/)
  {
    $self->{'LAST_ERROR'} = "Timed out after $timeout seconds.";
    return;
  }

  if(!$tracker || $@)
  {
    $self->{'LAST_ERROR'} = $@ || $! || 'Connection failed';
    return;
  }

  # 48 54 52 4B  00 01                                  HTRK..
  _hlc_write($self, $tracker, \HTRK_MAGIC, HTRK_MAGIC_LEN) || return;

  # 48 54 52 4B  00 01                                  HTRK..
  _hlc_buffered_read($self, $tracker, \$data, HTRK_MAGIC_LEN) || return;

  unless($data eq HTRK_MAGIC)
  {
    $self->{'LAST_ERROR'} = "Bad data from tracker.  Not a hotline tracker?";
    return;
  }

  # 00 01 1F F5  00 53 00 4A  | D1 9C 4B 86  15 7C 00 04  .....S.J..K..|..
  # ^^^^^^^^^^^  ^^^^^ ^^^^^  | ^^^^^^^^^^^  ^^^^^ ^^^^^
  # ???????????    |   ?????  | IP Address   Port  num users ...
  #              num servers  |
  _hlc_buffered_read($self, $tracker, \$data, 8) || return;

  $num_servers = unpack("n", substr($data, 4, 2));

  # Bug fixes here thanks to Les Brown <Les@hotlinecentral.com>
  while(@servers < $num_servers)
  {
    # 4 bytes for IP, 2 bytes for port, 2 bytes for num users
    unless(_hlc_buffered_read($self, $tracker, \$data, 4 + 2 + 2))
    {
      $tracker->close()  if($tracker->opened());
      return  unless(@servers);
      return (wantarray) ? @servers : \@servers;
    }

    # Skip these 8 bytes if the first byte was zero
    $byte1 = unpack("C", substr($data, 0, 1));
    next  if($byte1 == 0);

    $tli_ip        = join('.', map { unpack("C", $_) } split('', substr($data, 0, 4)));
    $tli_port      = unpack("n", substr($data, 4, 2));
    $tli_num_users = unpack("n", substr($data, 6, 2));

    # 2 null bytes, 1 byte for name len
    unless(_hlc_buffered_read($self, $tracker, \$data, 2 + 1))
    {
      $tracker->close()  if($tracker->opened());
      return  unless(@servers);
      return (wantarray) ? @servers : \@servers;
    }

    $length = unpack("C", substr($data, 2, 1));

    # $length bytes for name, 1 byte for description length
    unless(_hlc_buffered_read($self, $tracker, \$data, $length + 1))
    {
      $tracker->close()  if($tracker->opened());
      return  unless(@servers);
      return (wantarray) ? @servers : \@servers;
    }

    $length = unpack("C", chop($tli_name = $data));

    # $length bytes for description
    unless(_hlc_buffered_read($self, $tracker, \$tli_desc, $length))
    {
      $tracker->close()  if($tracker->opened());
      return  unless(@servers);
      return (wantarray) ? @servers : \@servers;
    }

    push(@servers, new Net::Hotline::TrackerListItem($tli_ip,
                                                     $tli_port,
                                                     $tli_num_users,
                                                     $tli_name,
                                                     $tli_desc));
  }

  $tracker->close()  if($tracker->opened());

  return (wantarray) ? @servers : \@servers;
}

sub pchat_invite
{
  my($self, $socket, $ref) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_al11_pchat_invite_now($socket, $ref);
  }
  else
  {
    return $self->_pchat_invite($socket, $ref);
  }
}

sub _al11_pchat_invite_now
{
  my($self, $socket, $ref) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->_pchat_invite($socket, $ref);
  $task = $self->{'TASKS'}->{$task_num};

  return(1)  if(defined($ref));

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return(1);
}

sub _pchat_invite
{
  my($self, $socket, $ref) = @_;

  my($data, $proto_header, $length, $task_num, $create);

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened());

  $create = defined($ref);

  # 8 bytes for socket atom + 6 or 8 bytes for pchat ref atom (optional)
  $length = 8 + (defined($ref)) ? (($ref > 0xFFFF) ? 8 : 6) : 0;

  $proto_header = new Net::Hotline::Protocol::Header;

  $proto_header->type(($create) ? HTLC_HDR_PCHAT_CREATE :
                                  HTLC_HDR_PCHAT_INVITE);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len($length);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header();

  # Socket of the user we're inviting
  $data .= pack("nnnn", ($create) ? 2 : 1,    # Num atoms
                        HTLC_DATA_SOCKET,     # Atom type
                        0x0002,               # Atom length
                        $socket);             # Atom value

  unless($create)
  {
    my($fmt) = ($ref > 0xFFFF) ? "nnN" : "nnn";

    # Private chat reference number
    $data .= pack($fmt, HTLC_DATA_PCHAT_REF,  # Atom type
                       ($ref > 0xFFFF) ? 4 :2,# Atom length
                       $ref);                 # Atom value
  }

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if($create)
  {
    if(_hlc_write($self, $server, \$data, length($data)))
    {
      _debug("NEW TASK: PCHAT INVITE/CREATE - $task_num\n");
      $self->{'TASKS'}->{$task_num} =
        new Net::Hotline::Task($task_num,HTLC_TASK_PCHAT_CREATE, time());
    }
    else { return }

    return($task_num);
  }
  else
  {
    if(_hlc_write($self, $server, \$data, length($data)))
    {
      _debug("PCHAT INVITE SOCKET($socket) TO PCHAT($ref)\n");
      return(1);
    }
    else { return }
  }
}

sub pchat_accept
{
  my($self, $ref) = @_;

  if($self->{'BLOCKING_TASKS'})
  {
    return $self->_al12_pchat_accept_now($ref);
  }
  else
  {
    return $self->_pchat_accept($ref);
  }
}

sub _al12_pchat_accept_now
{
  my($self, $ref) = @_;

  my($task, $task_num, $packet);

  $task_num = $self->_pchat_accept($ref);
  $task = $self->{'TASKS'}->{$task_num};

  return  unless($task_num);

  $packet = _blocking_task($self, $task_num);

  if($task->error())
  {
    $self->{'LAST_ERROR'} = $task->error_text();
    return;
  }

  return(1);
}

sub _pchat_accept
{
  my($self, $ref) = @_;

  my($data, $proto_header, $task_num);

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened() && defined($ref));

  $proto_header = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_PCHAT_ACCEPT);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(($ref > 0xFFFF) ? 10 : 8);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header();

  my($fmt) = ($ref > 0xFFFF) ? "nnnN" : "nnnn";

  # Pchat ref number atom
  $data .= pack($fmt, 0x0001,                 # Num atoms
                      HTLC_DATA_PCHAT_REF,    # Atom type
                      ($ref > 0xFFFF) ? 4 : 2,# Atom length
                      $ref);                  # Atom value

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    _debug("NEW TASK: PCHAT ACCEPT($ref) - $task_num\n");
    $self->{'TASKS'}->{$task_num} =
      new Net::Hotline::Task($task_num, HTLC_TASK_PCHAT_ACCEPT, time(), undef, undef, $ref);
  }
  else { return }

  return($task_num);
}

sub pchat_decline
{
  my($self, $ref) = @_;

  my($data, $proto_header, $task_num, $length);

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened() && defined($ref));

  $proto_header = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_PCHAT_DECLINE);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(($ref > 0xFFFF) ? 10 : 8);
  $proto_header->len2($proto_header->len);

  $data = $proto_header->header();

  my($fmt) = ($ref > 0xFFFF) ? "nnnN" : "nnnn";

  # Pchat ref number atom
  $data .= pack($fmt, 0x0001,                 # Num atoms
                      HTLC_DATA_PCHAT_REF,    # Atom type
                      ($ref > 0xFFFF) ? 4 : 2,# Atom length
                      $ref);                  # Atom value

  _debug(_hexdump($data));

  $task_num = $proto_header->seq();

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    return(1);
  }
  else { return }
}

sub al07_pchat_action
{
  my($self, $ref, @message) = @_;

  my($message) = join('', @message);

  $message =~ s/\n/@{[HTLC_NEWLINE]}/osg;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened() && defined($ref));

  my($data);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_CHAT);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len((($ref > 0xFFFF) ? 20 : 18) + length($message));
  $proto_header->len2($proto_header->len);

  my($fmt) = ($ref > 0xFFFF) ? "n6Nnn" : "n9";

  $data = $proto_header->header() .
          pack($fmt, 0x0003,                  # Num atoms

                     HTLC_DATA_OPTION,        # Atom type
                     0x0002,                  # Atom length
                     0x0001,                  # Atom data

                     HTLC_DATA_PCHAT_REF,     # Atom type
                     ($ref > 0xFFFF) ? 4 : 2, # Atom length
                     $ref,                    # Atom value

                     HTLC_DATA_CHAT,          # Atom type
                     length($message)) .      # Atom length
          $message;                           # Atom data

  _debug(_hexdump($data));

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    return(1);
  }
  else { return }
}

sub pchat
{
  my($self, $ref, @message) = @_;

  my($message) = join('', @message);

  $message =~ s/\n/@{[HTLC_NEWLINE]}/osg;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened() && defined($ref));

  my($data);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_CHAT);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len((($ref > 0xFFFF) ? 14 : 12) + length($message));
  $proto_header->len2($proto_header->len);

  my($fmt) = ($ref > 0xFFFF) ? "n3Nnn" : "n6";

  $data = $proto_header->header() .
          pack($fmt, 0x0002,                  # Num atoms

                     HTLC_DATA_PCHAT_REF,     # Atom type
                     ($ref > 0xFFFF) ? 4 : 2, # Atom length
                     $ref,                    # Atom value

                     HTLC_DATA_CHAT,          # Atom type
                     length($message)) .      # Atom length
          $message;                           # Atom data

  _debug(_hexdump($data));

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    return(1);
  }
  else { return }
}

sub pchat_leave
{
  my($self, $ref) = @_;

  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened() && defined($ref));

  my($data);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_PCHAT_CLOSE);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len(($ref > 0xFFFF) ? 10 : 8);
  $proto_header->len2($proto_header->len);

  my($fmt) = ($ref > 0xFFFF) ? "n3N" : "n4";

  $data = $proto_header->header() .
          pack($fmt, 0x0001,                  # Num atoms

                     HTLC_DATA_PCHAT_REF,     # Atom type
                     ($ref > 0xFFFF) ? 4 : 2, # Atom length
                     $ref);                   # Atom value

  _debug(_hexdump($data));

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    delete $self->{'PCHATS'}->{$ref};
    return(1);
  }
  else { return }
}

sub pchat_subject
{
  my($self, $ref, @subject) = @_;
  
  my($server) = $self->{'SERVER'} or croak "Not connected to a server";
  return  unless($server->opened() && defined($ref));

  my($subject) = join('', @subject);

  my($data);

  my($proto_header) = new Net::Hotline::Protocol::Header;

  $proto_header->type(HTLC_HDR_PCHAT_SUBJECT);
  $proto_header->seq($self->_next_seqnum());
  $proto_header->task(0x00000000);
  $proto_header->len((($ref > 0xFFFF) ? 14 : 12) + length($subject));
  $proto_header->len2($proto_header->len);

  my($fmt) = ($ref > 0xFFFF) ? "n3Nnn" : "n6";

  $data = $proto_header->header() .
          pack($fmt, 0x0002,                  # Num atoms

                     HTLC_DATA_PCHAT_REF,     # Atom type
                     ($ref > 0xFFFF) ? 4 : 2, # Atom length
                     $ref,                    # Atom value

                     HTLC_DATA_PCHAT_SUBJECT, # Atom type
                     length($subject)) .      # Atom length
          $subject;                           # Atom value

  _debug(_hexdump($data));

  if(_hlc_write($self, $server, \$data, length($data)))
  {
    return(1);
  }
  else { return }
}

1;
