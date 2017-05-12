#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More;

use File::Basename;

my $inc = join ' ', map { "-I\"$_\"" } @INC;
my $dir = dirname(__FILE__);

my $found;
for my $tz (qw( Poland CET-1CEST )) {
    $ENV{TZ} = $tz;
    if (`$^X $inc $dir/120_tmzone.pl %z 0 0 0 1 1 112` =~ /^\+0[12]00$/) {
        $found = 1;
        last;
    };
};

if ($found) {
    plan tests => 4;
}
else {
    plan skip_all => 'Missing tzdata on this system';
};

my @t1 = (0, 0, 0, 1, 1, 112);
my @t2 = (0, 0, 0, 1, 7, 112);

is `$^X $inc $dir/120_tmzone.pl %z @t1`, '+0100', "tmzone1";
is `$^X $inc $dir/120_tmzone.pl %Z @t1`, 'CET',   "tmname1";
is `$^X $inc $dir/120_tmzone.pl %z @t2`, '+0200', "tmzone2";
is `$^X $inc $dir/120_tmzone.pl %Z @t2`, 'CEST',  "tmname2";
