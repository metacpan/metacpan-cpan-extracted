package Net::Hotline::PrivateChat;

## Copyright(c) 1998-2002 by John C. Siracusa.  All rights reserved.  This
## program is free software; you can redistribute it and/or modify it under
## the same terms as Perl itself.

use strict;

use vars qw($VERSION);

$VERSION = '0.80';

sub new
{
  my($class, @args) = @_;

  my($self);

  if(@args)
  {
    $self =
    {    
      'REFERENCE' => $args[0],
      'USER_LIST' => $args[1],
      'SUBJECT'   => $args[2]
    };  
  }
  else
  {
    $self =
    {
      'REFERENCE' => undef,
      'USER_LIST' => undef,
      'SUBJECT'   => undef
    };
  }

  bless  $self, $class;
  return $self;
}

sub reference
{
  $_[0]->{'REFERENCE'} = $_[1]  if(@_ == 2);
  return $_[0]->{'REFERENCE'};
}

sub userlist
{
  $_[0]->{'USER_LIST'} = $_[1]  if(@_ == 2);
  return $_[0]->{'USER_LIST'};
}

sub subject
{
  $_[0]->{'SUBJECT'} = $_[1]  if(@_ == 2);
  return $_[0]->{'SUBJECT'};
}

1;
