#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib 'lib';

use Data::Printer;

# then in app.psgi
use Plack::Builder;

use Plack::App::HipChat::WebHook;

my $app = Plack::App::HipChat::WebHook->new({
    hipchat_user_agent => 'HipChat.com',
    webhooks => {
        '/webhook_notification' => sub {
            my $rh = shift;
            p $rh;
            return [ 200,
                     [ 'Content-Type' => 'text/plain' ],
                     [ 'Completed' ]
                 ];
        },
    },
})->to_app;
