#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Test::More;
use HTTP::Message::PSGI;
use HTTP::Request::Common;

use Plack::Builder;

exit main( @ARGV );

sub main
{

    my $app = builder
    {
        enable 'Plack::Middleware::BotDetector',
            bot_regex => qr/Googlebot|Baiduspider|Yahoo! Slurp/;

        \&test_for_bot;
    };

    for my $bot ( 'Googlebot UA', 'UA for Baiduspider', 'Yahoo! Slurp time!' )
    {
        my $req   = GET '/?expected_bot=1';
        $req->header( User_Agent => $bot );
        $app->( $req->to_psgi );
    }

    for my $user ( 'Mozilla', 'Webkit', 'Chrome' )
    {
        my $req   = GET '/?expected_bot=0';
        $req->header( User_Agent => $user );
        $app->( $req->to_psgi );
    }

    done_testing;
    return 0;
}

sub test_for_bot
{
    my $env          = shift;
    my $query_string = $env->{QUERY_STRING};
    my ($expect_bot) = $query_string =~ /expected_bot=(\d)/;

    if ($expect_bot)
    {
        ok $env->{'BotDetector.looks-like-bot'},
            "$env->{HTTP_USER_AGENT} should look like a bot";
    }
    else
    {
        ok ! $env->{'BotDetector.looks-like-bot'},
            "$env->{HTTP_USER_AGENT} should look unlike a bot";
    }
}
