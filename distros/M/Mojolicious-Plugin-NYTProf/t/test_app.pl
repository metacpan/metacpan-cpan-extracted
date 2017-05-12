#!perl

use strict;
use warnings;

use Mojolicious::Lite;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

plugin NYTProf => {
  nytprof => {
  },
};

get '/' => sub {
	sleep(1);
	shift->render(text => "Hello World");
};

app->start;
