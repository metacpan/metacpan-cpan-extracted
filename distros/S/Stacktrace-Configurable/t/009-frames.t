#!perl

use strict;
use warnings;
use Test::More;
use Stacktrace::Configurable;
use utf8;

my $trace = Stacktrace::Configurable->new(format=>'%f %l');
my $frames;

my $l1_line = __LINE__;
sub l1 {$frames = $trace->get_trace->frames}
l1;

for my $m (@Stacktrace::Configurable::attr) {
    ok eval {$trace->can($m)}, "trace can $m";
}

is $trace->format='hugo', 'hugo', 'format setter';
is $trace->format, 'hugo', 'format getter';

for my $m (@Stacktrace::Configurable::Frame::attr) {
    ok eval {$frames->[0]->can($m)}, "frame can $m";
}

is $frames->[0]->nr, 1, 'topmost frame->nr is 1';

done_testing;
