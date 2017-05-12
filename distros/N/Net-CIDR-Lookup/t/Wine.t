#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;

BEGIN {
    # Pretend we're on Windows and Socket::inet_pton does not work
    $^O = 'MSWin32';
    *Socket::inet_pton = sub { die "inet_pton is unimplemented on Windows!" };
    eval q[
        use Net::CIDR::Lookup;
        use warnings FATAL => 'all';
    ];
}

my $t = Net::CIDR::Lookup->new;
lives_ok(sub { $t->add('192.168.0.129/25', 42) }, 'Does not use inet_pton() on Windows');


