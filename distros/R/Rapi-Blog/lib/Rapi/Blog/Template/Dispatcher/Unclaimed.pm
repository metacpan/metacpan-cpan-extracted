package Rapi::Blog::Template::Dispatcher::Unclaimed;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use List::Util;

use Moo;
extends 'Rapi::Blog::Template::Dispatcher';

use Types::Standard ':all';

sub rank { 0 }

has '+claimed',             default => sub { 0 };
has '+maybe_psgi_response', default => sub { undef };


1;