#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Proc::ProcessTable;
use PerlX::Range;

{
    say "Before:";
    my $pt = new Proc::ProcessTable( 'cache_ttys' => 1 );
    my ($p) = grep { $_->pid eq $$ } @{ $pt->table };
    say $p->rss;
}

my $a = 1..100000;

{
    say "After Declare:";
    my $pt = new Proc::ProcessTable( 'cache_ttys' => 1 );
    my ($p) = grep { $_->pid eq $$ } @{ $pt->table };
    say $p->rss;
}

say "There are " . $a->items . " items in a";

{
    say "After Getting the number of items:";
    my $pt = new Proc::ProcessTable( 'cache_ttys' => 1 );
    my ($p) = grep { $_->pid eq $$ } @{ $pt->table };
    say $p->rss;
}
