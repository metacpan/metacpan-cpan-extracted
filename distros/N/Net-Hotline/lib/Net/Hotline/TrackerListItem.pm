package Net::Hotline::TrackerListItem;

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

  if(@args == 5)
  {
    $self =
    {    
      'ADDRESS'     => $args[0],
      'PORT'        => $args[1],
      'NUM_USERS'   => $args[2],
      'NAME'        => $args[3],
      'DESCRIPTION' => $args[4]
    };  
  }
  else
  {
    $self =
    {    
      'ADDRESS'     => undef,
      'PORT'        => undef,
      'NUM_USERS'   => undef,
      'NAME'        => undef,
      'DESCRIPTION' => undef
    };
  }

  bless  $self, $class;
  return $self;
}

sub address
{
  $_[0]->{'ADDRESS'} = $_[1]  if(@_ == 2);
  return $_[0]->{'ADDRESS'};
}

sub port
{
  $_[0]->{'PORT'} = $_[1]  if(@_ == 2);
  return $_[0]->{'PORT'};
}

sub num_users
{
  $_[0]->{'NUM_USERS'} = $_[1]  if(@_ == 2);
  return $_[0]->{'NUM_USERS'};
}

sub name
{
  $_[0]->{'NAME'} = $_[1]  if(@_ == 2);
  return $_[0]->{'NAME'};
}

sub description
{
  $_[0]->{'DESCRIPTION'} = $_[1]  if(@_ == 2);
  return $_[0]->{'DESCRIPTION'};
}

1;
