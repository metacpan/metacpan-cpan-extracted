#! /usr/bin/env perl
use strict;
use warnings;
use Qudo;

my $m = Qudo->new(
    databases => [+{
        dsn      => 'dbi:mysql:qudo',
        username => 'root',
        password => '',
    }],
);

for my $i (1..10000) {
    $m->enqueue('Worker::Test', {args => $i});
}
