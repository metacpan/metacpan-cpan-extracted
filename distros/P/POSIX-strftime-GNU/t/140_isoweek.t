#!/usr/bin/perl

use strict;
use warnings;

use Carp ();
use Config;
use File::Spec;
use Time::Local;

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 8;

BEGIN { use_ok 'POSIX::strftime::GNU'; }
BEGIN { use_ok 'POSIX', qw( strftime ); }

if ($Config{d_setlocale}) {
    POSIX::setlocale(&POSIX::LC_TIME, 'C');
}

is strftime('%gW%V', (0, 0, 0, 31, 11, 111)), '11W52', '2011-12-31';
is strftime('%gW%V', (0, 0, 0,  1,  0, 112)), '11W52', '2012-01-01';
is strftime('%gW%V', (0, 0, 0,  2,  0, 112)), '12W01', '2012-01-02';
is strftime('%gW%V', (0, 0, 0, 30, 11, 112)), '12W52', '2012-12-30';
is strftime('%gW%V', (0, 0, 0, 31, 11, 112)), '13W01', '2012-12-31';
is strftime('%gW%V', (0, 0, 0,  1,  0, 113)), '13W01', '2013-01-01';
