#!/usr/bin/perl -w

use strict;
use lib "..";
use OpenPlugin();

my $CONFIG_FILE = '/usr/local/etc/OpenPlugin.conf';

my $OP = OpenPlugin->new( config => { src => $CONFIG_FILE } );

$OP->log->warn( "Hello World!");
$OP->log->error( "Done!");
