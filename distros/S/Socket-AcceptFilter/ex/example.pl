#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use Socket::AcceptFilter;

my $fh;

socket $fh, AF_INET, SOCK_STREAM, 0
	or die "socket failed: $!";

bind $fh, Socket::pack_sockaddr_in(65529, Socket::inet_aton('127.0.0.1'))
	or die "bind failed: $!";

listen $fh or die "listen failed: $!";

# Now, after listen and before accept you could enable accept filter (it your OS supports it)

accept_filter($fh,'dataready');

