#!/usr/bin/env perl
use strict;
use 5.010;
use Benchmark ':all';
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Plift;
use Path::Tiny;

my $plift = Plift->new( path => ["$FindBin::Bin/plift"] );


my $num = shift || 1_000;



for (1..$num) {
    plift();
}

say 'Done - <ENTER>';
<STDIN>;




sub plift {
    my $output = $plift->process("index")->as_html;
}
