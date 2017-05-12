#!/usr/bin/perl

use strict;
use warnings;

use Carp ();
use Config;

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 3;

BEGIN { use_ok 'POSIX::strftime::GNU'; }
BEGIN { use_ok 'POSIX', qw( strftime ); }

if ($Config{d_setlocale}) {
    POSIX::setlocale(&POSIX::LC_TIME, 'C');
}

my $date = strftime('%A, %d-%b-%y %T %Z', localtime);

like $date, qr/^\w+, \d{2}-\w{3}-\d{2} \d{2}:\d{2}:\d{2} [\w+-]+$/, 'date in RFC850 format';
