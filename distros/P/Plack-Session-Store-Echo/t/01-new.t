#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Plack::Session::Store::Echo ();


my $str;

eval { $str = Plack::Session::Store::Echo->new; };
ok !$@ or print("Bail out!\n");
is ref($str), 'Plack::Session::Store::Echo';


done_testing;
