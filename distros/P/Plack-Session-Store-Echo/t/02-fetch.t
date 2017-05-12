#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Plack::Session::Store::Echo ();


my $str = Plack::Session::Store::Echo->new;

is ref($str->fetch()), 'HASH';
ok !%{$str->fetch()};


done_testing;
