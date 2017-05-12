#!/usr/bin/perl -w

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 5;

use Term::ProgressBar::Simple;
use Time::HiRes qw( sleep );

{
    diag "Testing simple ++ increment";

    my $progress = Term::ProgressBar::Simple->new(10_000);

    for ( 1 .. 10000 ) {
        $progress++;
    }

    pass 'tested ++';
}

{
    diag "Testing ++ increment with early exit";

    my $progress = Term::ProgressBar::Simple->new(10_000);

    for ( 1 .. 10000 ) {
        $progress++;
    }

}
pass 'tested ++ with early exit';

{
    diag "Testing += increment";

    my @squares = map { $_**2 } 1 .. 20;

    my $total = 0;
    $total += $_ for @squares;

    my $progress = Term::ProgressBar::Simple->new($total);

    for (@squares) {
        sleep 0.2;
        $progress += $_;
    }

    pass 'tested +=';
}

{
    diag "Testing message";

    my $progress = Term::ProgressBar::Simple->new(2);
    $progress->message('At the beginning');
    $progress++;
    $progress->message('At the middle');
    $progress++;
    $progress->message('At the end');
    pass 'tested message';
}

pass "made it to end of code";
