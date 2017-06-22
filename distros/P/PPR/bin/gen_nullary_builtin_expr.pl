#! /usr/bin/env perl

use 5.014;
use warnings;
use experimentals;
use Regexp::Optimizer;

my $builtins;
say Regexp::Optimizer->new->optimize($builtins);

BEGIN {
    $builtins = qr{
            fork
        |   endgrent
        |   endhostent
        |   endnetent
        |   endprotoent
        |   endpwent
        |   endservent
        |   getgrent
        |   gethostent
        |   getlogin
        |   getnetent
        |   getppid
        |   getprotoent
        |   getpwent
        |   getservent
        |   time
        |   times
        |   wait
        |   wantarray
    }x;
}

