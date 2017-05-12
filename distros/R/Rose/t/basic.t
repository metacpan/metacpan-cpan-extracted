#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;

BEGIN 
{
  use_ok('Rose');
  use_ok('Rose::Object');
  use_ok('Rose::DateTime');
  use_ok('Rose::URI');
  use_ok('Rose::HTML::Objects');
}

is(Rose->version, $Rose::VERSION, 'version()');
