#! /usr/bin/perl


use Test::More;
use strict;
use warnings;
use Socket;

plan tests => 4;

use_ok('Sphinx::Search');

my $sph_port = rand(12345);
my $fp;

# Create listening socket that never responds.
socket($fp, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or
    die("socket: $!");
bind($fp, sockaddr_in($sph_port, INADDR_ANY));
listen($fp, 1);

my $sphinx = Sphinx::Search->new({ port => $sph_port });
ok($sphinx, "Constructor");

my $t = time();
$sphinx->SetConnectTimeout(1);
ok(! $sphinx->_Connect, "connect");
ok(time < $t + 2, "Timeout");


