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

my $date = strftime('%a, %d %b %Y %T %z', localtime);

like $date, qr/^\w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} [+-]\d{4}$/, 'date in RFC822 format';
