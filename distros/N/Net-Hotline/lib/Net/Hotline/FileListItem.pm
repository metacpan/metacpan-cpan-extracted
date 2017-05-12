package Net::Hotline::FileListItem;

## Copyright(c) 1998-2002 by John C. Siracusa.  All rights reserved.  This
## program is free software; you can redistribute it and/or modify it under
## the same terms as Perl itself.

use strict;

use vars qw($VERSION);

$VERSION = '0.80';

sub new
{
  my($class, $data) = @_;
  my($self);

  if(defined($data))
  {
    my($name_len) = unpack("L", substr($data, 16, 4));

    $self =
    {
      'TYPE'     => substr($data, 0, 4),
      'CREATOR'  => substr($data, 4, 4),
      'SIZE'     => unpack("N", substr($data, 8, 4)),
      'UNKNOWN'  => substr($data, 12, 4),
      'NAME'     => substr($data, 20, $name_len)
    };
  }
  else
  {
    $self =
    {    
      'TYPE'     => undef,
      'CREATOR'  => undef,
      'SIZE'     => 0x00000000,
      'UNKNOWN'  => 0x00000000,
      'NAME'     => undef
    };
  }

  bless  $self, $class;
  return $self;
}

sub type
{
  $_[0]->{'TYPE'} = $_[1]  if(@_ == 2);
  return $_[0]->{'TYPE'};
}

sub creator
{
  $_[0]->{'CREATOR'} = $_[1]  if(@_ == 2);
  return $_[0]->{'CREATOR'};
}

sub size
{
  $_[0]->{'SIZE'} = $_[1]  if(@_ == 2);
  return $_[0]->{'SIZE'};
}

sub name
{
  $_[0]->{'NAME'} = $_[1]  if(@_ == 2);
  return $_[0]->{'NAME'};
}

1;
