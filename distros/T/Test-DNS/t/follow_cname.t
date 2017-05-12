#!/usr/bin/perl

use strict;
use warnings;

use Test::DNS;
use Test::More;

plan skip_all => 'requires AUTHOR_TESTING' unless $ENV{'AUTHOR_TESTING'};

my $dns   = Test::DNS->new( warnings => 0 );
my @p_ips = qw/207.171.7.41 207.171.7.51/;

$dns->is_cname( 'www.perl.org' => 'varnish-lb.develooper.com' );
$dns->is_a( 'varnish-lb.develooper.com' => \@p_ips );

$dns->follow_cname(1);
$dns->is_a( 'www.perl.org' => \@p_ips );

done_testing();
