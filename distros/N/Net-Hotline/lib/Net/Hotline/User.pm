package Net::Hotline::User;

## Copyright(c) 1998-2002 by John C. Siracusa.  All rights reserved.  This
## program is free software; you can redistribute it and/or modify it under
## the same terms as Perl itself.

use strict;

use vars qw($VERSION);

$VERSION = '0.80';

sub new
{
  my($class, @args) = @_;

  my($data) = join('', @args);

  my($self);

  if(@args == 5)
  {
    $self =
    {
      'SOCKET'    => $args[0],
      'NICK'      => $args[1],
      'LOGIN'     => $args[2],
      'ICON'      => $args[3],
      'COLOR'     => $args[4],
      'INFO'      => undef
    };
  }
  elsif(@args == 1)
  {
    my($nick_len) = unpack("n", substr($data, 6, 2));

    $self =
    {
      'SOCKET'    => unpack("n", substr($data, 0, 2)),
      'ICON'      => unpack("n", substr($data, 2, 2)),
      'COLOR'     => unpack("n", substr($data, 4, 2)),
      'NICK'      => join('', substr($data, 8, $nick_len)),
      'LOGIN'     => undef,
      'INFO'      => undef
    };
  }
  else
  {
    $self =
    {
      'SOCKET'    => undef,
      'NICK'      => undef,
      'LOGIN'     => undef,
      'ICON'      => undef,
      'COLOR'     => undef,
      'INFO'      => undef
    };
  }

  bless  $self, $class;
  return $self;
}

sub socket
{
  $_[0]->{'SOCKET'} = $_[1]  if(@_ > 1 && $_[1] =~ /^\d+$/);
  return $_[0]->{'SOCKET'};
}

sub nick
{
  $_[0]->{'NICK'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'NICK'};
}

sub login
{
  $_[0]->{'LOGIN'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'LOGIN'};
}

sub icon
{
  $_[0]->{'ICON'} = $_[1]  if(@_ > 1 && $_[1] =~ /^-?\d+$/);
  return $_[0]->{'ICON'};
}

sub color
{
  $_[0]->{'COLOR'} = $_[1]  if(@_ > 1 && $_[1] =~ /^\d+$/);
  return $_[0]->{'COLOR'};
}

sub info
{
  $_[0]->{'INFO'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'INFO'};
}

1;
