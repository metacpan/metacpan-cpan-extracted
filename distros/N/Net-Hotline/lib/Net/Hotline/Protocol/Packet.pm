package Net::Hotline::Protocol::Packet;

## Copyright(c) 1998-2002 by John C. Siracusa.  All rights reserved.  This
## program is free software; you can redistribute it and/or modify it under
## the same terms as Perl itself.

use strict;

use vars qw($VERSION);

use Carp;
use POSIX qw(:errno_h);
use Net::Hotline::User;
use Net::Hotline::FileListItem;
use Net::Hotline::Protocol::Header;
use Net::Hotline::Shared qw(:all);
use Net::Hotline::Constants
  qw(HTLC_DATA_PCHAT_SUBJECT HTLC_DATA_RFLT HTLC_EWOULDBLOCK HTLC_NEWLINE
     HTLS_DATA_AGREEMENT HTLS_DATA_CHAT HTLS_DATA_COLOR
     HTLS_DATA_FILE_COMMENT HTLS_DATA_FILE_CREATOR HTLS_DATA_FILE_CTIME
     HTLS_DATA_FILE_ICON HTLS_DATA_FILE_LIST HTLS_DATA_FILE_MTIME
     HTLS_DATA_FILE_NAME HTLS_DATA_FILE_SIZE HTLS_DATA_FILE_TYPE
     HTLS_DATA_HTXF_REF HTLS_DATA_HTXF_SIZE HTLS_DATA_ICON HTLS_DATA_MSG
     HTLS_DATA_NEWS HTLS_DATA_NEWS_POST HTLS_DATA_NICKNAME
     HTLS_DATA_PCHAT_REF HTLS_DATA_SERVER_MSG HTLS_DATA_SOCKET
     HTLS_DATA_TASK_ERROR HTLS_DATA_USER_INFO HTLS_DATA_USER_LIST
     HTLS_HDR_TASK SIZEOF_HL_PROTO_HDR HTLS_DATA_REPLY HTLS_DATA_IS_REPLY);

$VERSION = '0.80';

sub new
{
  my($class) = shift;
  my($self);

  $self =
  {
    'PROTO_HEADER' => undef,

    'USER_LIST'    => undef,
    'FILE_LIST'    => undef,
    'USER_INFO'    => undef,
    'NEWS'         => undef,

    'SOCKET'       => undef,
    'ICON'         => undef,
    'COLOR'        => undef,
    'NICK'         => undef,
    'TASK_ERROR'   => undef,
    'DATA'         => undef,

    'FILE_ICON'    => undef,
    'FILE_TYPE'    => undef,
    'FILE_CREATOR' => undef,
    'FILE_SIZE'    => undef,
    'FILE_NAME'    => undef,
    'FILE_COMMENT' => undef,
    'FILE_CTIME'   => undef,
    'FILE_MTIME'   => undef,

    'HTXF_SIZE'    => undef,
    'HTXF_REF'     => undef,
    'HTXF_RFLT'    => undef,

    'PCHAT_REF'    => undef,

    'IS_REPLY'     => undef,
    'REPLY_TO'     => undef,

    'TYPE'         => undef
  };

  bless  $self, $class;
  return $self;
}

sub clear
{
  my($self) = shift;

  $self->{'PROTO_HEADER'} = 

  $self->{'USER_LIST'}    =
  $self->{'FILE_LIST'}    =
  $self->{'USER_INFO'}    =
  $self->{'NEWS'}         = 

  $self->{'SOCKET'}       =
  $self->{'ICON'}         =
  $self->{'COLOR'}        =
  $self->{'NICK'}         = 
  $self->{'TASK_ERROR'}   =  
  $self->{'DATA'}         = 

  $self->{'FILE_ICON'}    =
  $self->{'FILE_TYPE'}    =
  $self->{'FILE_CREATOR'} =
  $self->{'FILE_SIZE'}    =
  $self->{'FILE_NAME'}    =
  $self->{'FILE_COMMENT'} =
  $self->{'FILE_CTIME'}   =
  $self->{'FILE_MTIME'}   =

  $self->{'HTXF_SIZE'}    =
  $self->{'HTXF_REF'}     =
  $self->{'HTXF_RFLT'}    =

  $self->{'PCHAT_REF'}    = 

  $self->{'IS_REPLY'}     =
  $self->{'REPLY_TO'}     =

  $self->{'TYPE'} = undef;
}

sub read_parse
{
  my($self, $fh, $blocking) = @_;

  my($data, $length, $atom_count, $atom_type, $atom_len, $read_err,
     $nick, $socket, $icon, $user_type, $name, $color, $read);

  $self->clear();

  unless($fh->opened())
  {
    $self->{'TYPE'} = 'DISCONNECTED';
    return(1);
  }

  $read = _read($fh, \$data, SIZEOF_HL_PROTO_HDR, $blocking);
  $read_err = 0 + $!; # Get the numerical value of the magical $!

  unless(defined($read) && $read > 0)
  {
    if($read_err == EWOULDBLOCK || $read_err == EAGAIN)
    {
      #_debug("WOULDBLOCK\n");
      return(HTLC_EWOULDBLOCK);
    }
    elsif($read_err == ECONNRESET || $read_err == ECONNABORTED ||
          $read_err == ENOTCONN)
    {
      #_debug("DISCONNECTED\n");
      $self->clear();
      $self->{'TYPE'} = 'DISCONNECTED';
      return(1);
    }
    else
    {
      # I'm assuming this is a MacPerl bug: sysread() sometimes returns
      # undefined without setting $!.  I use the "shrug and continue"
      # method here and just treat it as an idle event.
      return(HTLC_EWOULDBLOCK)  if($^O eq 'MacOS');

      # It's fatal on non-Mac OS systems, however.
      die "sysread() error($read_err): $!\n";

      # I'm also getting:
      #
      #  sysread() error(145): Connection timed out 
      #
      # On Solaris.  Hmmmm...
    }
  }

  _debug("Packet data:\n", _hexdump($data));

  $self->{'PROTO_HEADER'} = new Net::Hotline::Protocol::Header($data);

  $length = unpack("N", $self->{'PROTO_HEADER'}->len());
  $self->{'TYPE'} = unpack("N", $self->{'PROTO_HEADER'}->type());

  if($self->{'TYPE'} == HTLS_HDR_TASK)
  {
    $self->{'TASK_NUM'} = unpack("N", $self->{'PROTO_HEADER'}->seq());
  }

  $length -= _read($fh, \$atom_count, 2);
  $atom_count = unpack("n", $atom_count);

  _debug("Atom count: $atom_count\n");

  for(; $atom_count != 0; $atom_count--)
  {
    # This probably doesn't need to be here anymore, but just to be safe...
    if($length < 4)
    {
      $length -= _read($fh, \$data, $length);
      _debug("Slurped up < 4 bytes, length = $length\n");
      return(1);
    }

    $length -= _read($fh, \$atom_type, 2);
    $length -= _read($fh, \$atom_len, 2);

    _debug("Atom type:\n",  _hexdump($atom_type));
    _debug("Atom length:\n", _hexdump($atom_len));

    $atom_type = unpack("n", $atom_type);
    $atom_len = unpack("n", $atom_len);

    if($atom_type == HTLS_DATA_USER_LIST)
    {
      my($user_data, $user);

      $length -= _read($fh, \$user_data, $atom_len);

      $user = new Net::Hotline::User($user_data);

      _debug(" Nick: ", $user->nick(), "\n",
             " Icon: ", $user->icon(), "\n",
            "Socket: ", $user->socket(), "\n",
            " Color: ", $user->color(), "\n");

      $self->{'USER_LIST'}->{$user->socket()} = $user;
    }
    elsif($atom_type == HTLS_DATA_FILE_LIST)
    {
      my($file_data, $file);

      $length -= _read($fh, \$file_data, $atom_len);

      $file = new Net::Hotline::FileListItem($file_data);

      _debug("   Type: ", $file->type(), "\n",
             "Creator: ", $file->creator(), "\n",
             "   Size: ", $file->size(), "\n",
             "   Name: ", $file->name(), "\n");

      push(@{$self->{'FILE_LIST'}}, $file);
    }
    elsif($atom_type == HTLS_DATA_SOCKET)
    {
      $length -= _read($fh, \$socket, $atom_len);

      _debug("Socket: ", _hexdump($socket));

      # Older versions of the Hotline server sent socket numbers
      # in 4 bytes.  Newer versions send it in 2.  Nice.
      if($atom_len == 4)
      {
        $self->{'SOCKET'} = unpack("N", $socket);
      }
      else
      {
        $self->{'SOCKET'} = unpack("n", $socket);
      }
    }
    elsif($atom_type == HTLS_DATA_ICON)
    {
      $length -= _read($fh, \$icon, $atom_len);

      _debug("Icon: ", _hexdump($icon));

      $self->{'ICON'} = unpack("n", $icon);
    }
    elsif($atom_type == HTLS_DATA_COLOR)
    {
      $length -= _read($fh, \$color, $atom_len);

      _debug("Color: ", _hexdump($color));

      $self->{'COLOR'} = unpack("n", $color);
    }
    elsif($atom_type == HTLS_DATA_NICKNAME)
    {
      $length -= _read($fh, \$nick, $atom_len);

      _debug("Nick: ", _hexdump($nick));

      $self->{'NICK'} = $nick;
    }
    elsif($atom_type == HTLS_DATA_TASK_ERROR)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("Task error:\n", _hexdump($data));

      $data =~ s/@{[HTLC_NEWLINE]}/\n/osg;
      $self->{'TASK_ERROR'} = $data;
    }
    elsif($atom_type == HTLS_DATA_FILE_ICON)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("File icon:\n", _hexdump($data));

      $self->{'FILE_ICON'} = unpack("n", $data);
    }
    elsif($atom_type == HTLS_DATA_FILE_TYPE)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("File type:\n", _hexdump($data));

      $self->{'FILE_TYPE'} = $data;
    }
    elsif($atom_type == HTLS_DATA_FILE_CREATOR)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("File creator:\n", _hexdump($data));

      $self->{'FILE_CREATOR'} = $data;
    }
    elsif($atom_type == HTLS_DATA_FILE_SIZE)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("File size:\n", _hexdump($data));

      if($atom_len == 2) # Grrrrrrr...
      {
        $self->{'FILE_SIZE'} = unpack("n", $data);
      }
      else
      {
        $self->{'FILE_SIZE'} = unpack("N", $data);
      }
    }
    elsif($atom_type == HTLS_DATA_FILE_NAME)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("File name:\n", _hexdump($data));

      $self->{'FILE_NAME'} = $data;
    }
    elsif($atom_type == HTLS_DATA_FILE_COMMENT)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("File comment:\n", _hexdump($data));

      $self->{'FILE_COMMENT'} = $data;
    }
    elsif($atom_type == HTLS_DATA_FILE_CTIME)
    {
      $length -= _read($fh, \$data, $atom_len);

      $data =~ s/^....//;
      _debug("File ctime:\n", _hexdump($data));

      $self->{'FILE_CTIME'} = unpack("N", $data);
    }
    elsif($atom_type == HTLS_DATA_FILE_MTIME)
    {
      $length -= _read($fh, \$data, $atom_len);

      $data =~ s/^....//;
      _debug("File mtime:\n", _hexdump($data));

      $self->{'FILE_MTIME'} = unpack("N", $data);
    }
    elsif($atom_type == HTLS_DATA_PCHAT_REF)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("Private chat ref: ", _hexdump($data));

      # Server 1.2.1 gives chat refs in 2 bytes.  Annoying!
      if($atom_len == 2) 
      {
        $self->{'PCHAT_REF'} = unpack("n", $data);
      }
      else
      {
        $self->{'PCHAT_REF'} = unpack("N", $data);
      }
    }
    elsif($atom_type == HTLS_DATA_IS_REPLY)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("Is reply:\n", _hexdump($data));
      
      $self->{'IS_REPLY'} = unpack("n", $data);
    }
    elsif($atom_type == HTLS_DATA_REPLY)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("In reply to:\n", _hexdump($data));

      $data =~ s/@{[HTLC_NEWLINE]}/\n/osg;
      $self->{'REPLY_TO'} = $data;
    }
    elsif($atom_type == HTLS_DATA_MSG           ||
          $atom_type == HTLS_DATA_NEWS          ||
          $atom_type == HTLS_DATA_AGREEMENT     ||
          $atom_type == HTLS_DATA_USER_INFO     ||
          $atom_type == HTLS_DATA_CHAT          ||
          $atom_type == HTLC_DATA_PCHAT_SUBJECT ||
          $atom_type == HTLS_DATA_MSG           ||
          $atom_type == HTLS_DATA_SERVER_MSG    ||
          $atom_type == HTLS_DATA_NEWS_POST)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("Data:\n", _hexdump($data));

      $data =~ s/@{[HTLC_NEWLINE]}/\n/osg;
      $self->{'DATA'} = $data;
    }
    elsif($atom_type == HTLS_DATA_HTXF_SIZE)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("HTXF size:\n", _hexdump($data));

      if($atom_len == 2)
      {
        $self->{'HTXF_SIZE'} = unpack("n", $data);
      }
      else
      {
        $self->{'HTXF_SIZE'} = unpack("N", $data);
      }
    }
    elsif($atom_type == HTLS_DATA_HTXF_REF)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("HTXF ref:\n", _hexdump($data));

      $self->{'HTXF_REF'} = unpack("N", $data);
    }
    elsif($atom_type == HTLC_DATA_RFLT)
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("HTXF RFLT:\n", _hexdump($data));

      $self->{'HTXF_RFLT'} = $data;
    }
    else
    {
      $length -= _read($fh, \$data, $atom_len);

      _debug("Default data:\n", _hexdump($data));
      $self->{'DATA'} = $data;
    }
  }

  if($length > 0) # Should not be reached...
  {
    _debug("Left-over length!\n");

    while($length > 0)
    {
      $length -= _read($fh, \$data, $length);
      _debug("Left over data:\n", _hexdump($data));
    }
  }

  return(1);
}

1;
