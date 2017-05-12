package Net::Hotline::Protocol::Header;

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
    $self =
    {
      'TYPE' => substr($data, 0, 4),
      'SEQ'  => substr($data, 4, 4),
      'TASK' => substr($data, 8, 4),
      'LEN'  => substr($data, 12, 4),
      'LEN2' => substr($data, 16, 4)
    };
  }
  else
  {
    $self =
    {
      'TYPE' => 0x00000000,
      'SEQ'  => 0x00000000,
      'TASK' => 0x00000000,
      'LEN'  => 0x00000000,
      'LEN2' => 0x00000000
    };
  }

  bless  $self, $class;
  return $self;
}

sub type
{
  $_[0]->{'TYPE'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'TYPE'};
}

sub seq
{
  $_[0]->{'SEQ'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'SEQ'};
}

sub task
{
  $_[0]->{'TASK'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'TASK'};
}

sub len
{
  $_[0]->{'LEN'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'LEN'};
}

sub len2
{
  $_[0]->{'LEN2'} = $_[1]  if(defined($_[1]));
  return $_[0]->{'LEN2'};
}

sub header
{
  return pack("N5", $_[0]->{'TYPE'},
                    $_[0]->{'SEQ'},
                    $_[0]->{'TASK'},
                    $_[0]->{'LEN'},
                    $_[0]->{'LEN2'});
}

1;
