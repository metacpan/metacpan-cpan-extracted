#!perl -T

use Test::More tests => 3;

use_ok( 'Plack::App::PubSubHubbub::Subscriber' );
use_ok( 'Plack::App::PubSubHubbub::Subscriber::Client' );
use_ok( 'Plack::App::PubSubHubbub::Subscriber::Config' );

