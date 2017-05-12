#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Plack::Test::Agent;

my $app = sub
{
    my $content = shift->{HTTP_ACCEPT_LANGUAGE};
    return [ 200, [], [ $content ] ];
};

my $agent = Plack::Test::Agent->new( app => $app );

my $res = $agent->get( '/', 'Accept-Language' => 'en' );
is $res->content, 'en';

done_testing;
