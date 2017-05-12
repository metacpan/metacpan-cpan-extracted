#!/usr/bin/env perl

use strict;
use lib 'lib';
use MogileFS::REST;

## get the configuration for this app
my $servers;
if (my $cnf = $ENV{MOGILEFS_REST_SERVERS}) {
    $servers = [  split /,/, $cnf ];
}
my $default_class = $ENV{MOGILEFS_REST_DEFAULT_CLASS} || "normal";
my $largefile = defined $ENV{MOGILEFS_REST_LARGEFILE}
              ? $ENV{MOGILEFS_REST_LARGEFILE}
              : 0;

## instantiate a new app
my $app = MogileFS::REST->new(
    servers => $servers,
    default_class => $default_class,
    largefile => $largefile,
);

## psgi run it
$app->run();
