#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy} };

# workaround for HTTP::Tiny + Test::TCP
BEGIN { $INC{'threads.pm'} = 0 };
sub threads::tid { }

use Plack::Loader;
use Test::More;
use Test::TCP qw(empty_port);

if ($^O eq 'MSWin32' and $] >= 5.016 and $] < 5.019005 and not $ENV{PERL_TEST_BROKEN}) {
    plan skip_all => 'Perl with bug RT#119003 on MSWin32';
    exit 0;
}

if ($^O eq 'cygwin' and not eval { require Win32::Process; }) {
    plan skip_all => 'Win32::Process required';
    exit 0;
}

my $thrall = Plack::Loader->load(
    'Starlight',
    min_reqs_per_child => 5,
    max_reqs_per_child => 10,
    quiet => 1,
);

sleep 1;

my ($min, $max) = (7, 7);
for (my $i = 0; $i < 10000; $i++) {
    my $n = $thrall->_calc_reqs_per_child();
    $min = $n
        if $n < $min;
    $max = $n
        if $n > $max;
}

is $min, 5, "min";
is $max, 10, "max";

done_testing;
