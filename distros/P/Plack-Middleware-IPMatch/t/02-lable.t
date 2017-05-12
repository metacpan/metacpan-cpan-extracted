#!/usr/bin/perl
use strict;
use Test::More;
use File::Temp;
use Plack::Test;
use Plack::Builder;
use Plack::Request;
use HTTP::Request::Common;

BEGIN {
        eval q{ require File::Temp } or plan skip_all => 'Could not require File::Temp';
        eval q{ require HTTP::Request::Common } or plan skip_all => 'Could not require HTTP::Request::Common';
}

sub create_ip_file {
    my $out = File::Temp->new(UNLINK => 0);
    while (<DATA>) {
        print $out $_;
    }
    return $out->filename;
}

my $ipfile = create_ip_file();

my %test_data = (
   '202.106.0.20'    => 'CNC',
   '203.174.65.12'   => 'JP',
   '212.208.74.140'  => 'FR',
   '200.219.192.106' => 'BR',
   '210.25.5.5'      => 'CN',
   '192.37.150.150'  => 'CH',
   '192.106.51.100'  => 'IT',
   );

while (my ($remote_addr, $lable) = each %test_data) {
    my $app = builder {
        enable sub {
            my $app = shift;
            sub { $_[0]->{REMOTE_ADDR} = $remote_addr; $app->($_[0]) }; # fake remote address
        };
        enable 'Plack::Middleware::IPMatch', 
            IPFile => $ipfile;
        sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ $_[0]->{IPMATCH_LABEL} ] ] };
    };
    
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/');
        is $res->content, $lable;
    };
}
unlink $ipfile;

done_testing;

__DATA__
202.106.0.20/24 CNC
203.174.65.12/24 JP
212.208.74.140/24 FR
200.219.192.106/24 BR
210.25.5.5/24 CN
210.54.122.1/24 NZ
210.25.15.5/24 CN
192.37.51.100/24 CH
192.37.150.150/24 CH
192.106.51.100/24 IT
192.106.150.150/24 IT
