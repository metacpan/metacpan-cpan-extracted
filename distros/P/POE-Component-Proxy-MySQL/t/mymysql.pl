#!/usr/bin/env perl

use lib qw( 
   ./lib 
   ../lib 
);

use MyMySQL;

my $server = MyMySQL->new_with_options();

$server->run;


