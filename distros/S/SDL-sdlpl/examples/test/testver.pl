#!/usr/bin/perl -w

use strict;
use SDL::App;

my $app=new SDL::App;

printf("Compiled version: %d.%d.%d\n",   $app->compile_info());
printf("Linked version: %d.%d.%d\n",     $app->link_info());
printf("This is a %s endian machine.\n", $app->endianess());
