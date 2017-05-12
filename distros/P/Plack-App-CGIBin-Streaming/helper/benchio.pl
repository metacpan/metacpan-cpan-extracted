#!/usr/bin/perl

use strict;
use Benchmark qw/:hireswallclock :all/;

BEGIN {
    package PerlIO::via::XX;

    sub PUSHED {
        my ($class, $mode, $fh) = @_;

        my $dummy;
        return bless \$dummy, $class;
    }

    sub WRITE {$main::p and warn "perlio $_[1]"; return length $_[1]}
    sub FLUSH {}
    sub FILL {die "This layer supports write operations only"}
}

BEGIN {
    package My::Tie;
    use parent 'Tie::Handle';

    sub TIEHANDLE {
        my ($class) = @_;

        my $dummy;
        return bless \$dummy, $class;
    }

    sub WRITE {$main::p and warn "tie    $_[1]"; return length $_[1]}
}

open P, '>:via(XX)', '/dev/null';
tie *T, 'My::Tie';

{
    local our $p=1;
    print P "test\n";
    print T "test\n";
}

cmpthese timethese -5,
    {
     perlio => sub {print F "x"},
     tie    => sub {print T "x"},
    };

binmode P;
untie *T;
