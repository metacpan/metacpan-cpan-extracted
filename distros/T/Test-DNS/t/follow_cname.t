#!/usr/bin/perl

use strict;
use warnings;

use Test::DNS;
use Test::More;

plan 'skip_all' => 'requires AUTHOR_TESTING' unless $ENV{'AUTHOR_TESTING'};

my @p_ips = qw/207.171.7.55 207.171.7.45/;

subtest 'No following CNAME' => sub {
    my $dns   = Test::DNS->new();
    my $cname = 'klb.develooper.com';
    $dns->is_cname( 'www.perl.com' => $cname );
    $dns->is_a( $cname => \@p_ips );
};

subtest 'CNAME' => sub {
    my $dns = Test::DNS->new( 'follow_cname' => 1 );
    $dns->is_a( 'www.perl.com' => \@p_ips );
};

done_testing();
