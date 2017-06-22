#!/usr/bin/env perl
use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Stream;
use Ryu::Async;

use Log::Any::Adapter qw(Stderr), log_level => 'info';

my $loop = IO::Async::Loop->new;
$loop->add(
	my $ryu = Ryu::Async->new
);

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

$ryu->stdin
    ->decode('UTF-8')
    ->by_line
    ->say
    ->await;

