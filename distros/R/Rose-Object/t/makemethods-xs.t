#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin);

BEGIN
{
  eval { require Class::XSAccessor };

  if($@)
  {
    require Test::More;
    Test::More->import(skip_all => 'Class::XSAccessor not installed');
  }
  else
  {
    $ENV{'ROSE_OBJECT_NO_CLASS_XSACCESOR'} = 0;
    do "$Bin/makemethods.t";
  }
}
