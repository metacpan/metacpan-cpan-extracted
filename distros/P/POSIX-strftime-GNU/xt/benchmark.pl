#!/usr/bin/perl

use lib 'blib/arch', 'blib/lib', '../blib/arch', '../blib/lib';

use POSIX ();
use POSIX::strftime::GNU::PP;

POSIX::setlocale(&POSIX::LC_TIME, 'C');


our %tests = (

    '01_POSIX_822' => sub {
        POSIX::strftime('%a, %d %b %Y %T %z', localtime);
    },
    '02_POSIX_850' => sub {
        POSIX::strftime('%A, %d-%b-%y %T %Z', localtime);
    },

    eval q{ use POSIX::strftime::GNU::XS; 1 } ? (

    '03_XS_822' => sub {
        POSIX::strftime::GNU::XS::strftime('%a, %d %b %Y %T %z', localtime);
    },
    '04_XS_850' => sub {
        POSIX::strftime::GNU::XS::strftime('%A, %d-%b-%y %T %Z', localtime);
    },

    ) : (),

    '05_PP_822' => sub {
        POSIX::strftime::GNU::PP::strftime('%a, %d %b %Y %T %z', localtime);
    },
    '06_PP_850' => sub {
        POSIX::strftime::GNU::PP::strftime('%A, %d-%b-%y %T %Z', localtime);
    },

);


use Benchmark ();

my $result = Benchmark::timethese($ARGV[0] || -1, { %tests });
Benchmark::cmpthese($result);
