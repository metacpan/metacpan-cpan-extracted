#!perl

use strict;
use warnings;
use Test::More tests => 10;
use Net::Jabber::Bot;

# stuff for mock client object
use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient; # Test object

my %forums_and_responses;
$forums_and_responses{'test_forum1'} = ["jbot:", ""];

# Test 1: from_full attribute produces correct formatted string
{
    my $bot = Net::Jabber::Bot->new(
        server               => 'talk.google.com',
        conference_server     => 'conference.talk.google.com',
        port                 => 5222,
        username             => 'testuser',
        password             => 'testpass',
        alias                => 'testbot',
        forums_and_responses => \%forums_and_responses,
    );

    is($bot->from_full, 'testuser@talk.google.com/testbot',
       "from_full produces correctly formatted user\@server/alias string");
}

# Test 2: from_full with lazy defaults for alias
{
    my $bot = Net::Jabber::Bot->new(
        server               => 'jabber.example.com',
        conference_server     => 'conference.jabber.example.com',
        port                 => 5222,
        username             => 'myuser',
        password             => 'mypass',
        forums_and_responses => \%forums_and_responses,
    );

    like($bot->from_full, qr/^myuser\@jabber\.example\.com\//,
         "from_full starts with username\@server/ when alias defaults");
}

# Test 3: gtalk parameter enables TLS
{
    my $bot = Net::Jabber::Bot->new(
        server               => 'talk.google.com',
        conference_server     => 'conference.talk.google.com',
        port                 => 5222,
        username             => 'testuser',
        password             => 'testpass',
        alias                => 'testbot',
        gtalk                => 1,
        forums_and_responses => \%forums_and_responses,
    );

    is($bot->tls, 1, "gtalk => 1 enables TLS");
}

# Test 4: gtalk parameter sets server_host to gmail.com
{
    my $bot = Net::Jabber::Bot->new(
        server               => 'talk.google.com',
        conference_server     => 'conference.talk.google.com',
        port                 => 5222,
        username             => 'testuser',
        password             => 'testpass',
        alias                => 'testbot',
        gtalk                => 1,
        forums_and_responses => \%forums_and_responses,
    );

    is($bot->server_host, 'gmail.com',
       "gtalk => 1 sets server_host to gmail.com");
}

# Test 5: gtalk does not override explicit tls setting
{
    my $bot = Net::Jabber::Bot->new(
        server               => 'talk.google.com',
        conference_server     => 'conference.talk.google.com',
        port                 => 5222,
        username             => 'testuser',
        password             => 'testpass',
        alias                => 'testbot',
        gtalk                => 1,
        tls                  => 0,
        forums_and_responses => \%forums_and_responses,
    );

    # gtalk should force tls on regardless
    is($bot->tls, 1, "gtalk => 1 forces TLS even if tls => 0 was passed");
}

# Test 6: gtalk does not override explicit server_host
{
    my $bot = Net::Jabber::Bot->new(
        server               => 'talk.google.com',
        conference_server     => 'conference.talk.google.com',
        port                 => 5222,
        username             => 'testuser',
        password             => 'testpass',
        alias                => 'testbot',
        gtalk                => 1,
        server_host          => 'custom.google.com',
        forums_and_responses => \%forums_and_responses,
    );

    is($bot->server_host, 'custom.google.com',
       "gtalk => 1 does not override explicit server_host");
}

# Test 7: without gtalk, tls defaults to 0
{
    my $bot = Net::Jabber::Bot->new(
        server               => 'jabber.example.com',
        conference_server     => 'conference.jabber.example.com',
        port                 => 5222,
        username             => 'testuser',
        password             => 'testpass',
        alias                => 'testbot',
        forums_and_responses => \%forums_and_responses,
    );

    is($bot->tls, 0, "Without gtalk, tls defaults to 0");
}

# Test 8: without gtalk, server_host defaults to server
{
    my $bot = Net::Jabber::Bot->new(
        server               => 'jabber.example.com',
        conference_server     => 'conference.jabber.example.com',
        port                 => 5222,
        username             => 'testuser',
        password             => 'testpass',
        alias                => 'testbot',
        forums_and_responses => \%forums_and_responses,
    );

    is($bot->server_host, 'jabber.example.com',
       "Without gtalk, server_host defaults to server value");
}

# Test 9: gtalk => 0 does not change defaults
{
    my $bot = Net::Jabber::Bot->new(
        server               => 'jabber.example.com',
        conference_server     => 'conference.jabber.example.com',
        port                 => 5222,
        username             => 'testuser',
        password             => 'testpass',
        alias                => 'testbot',
        gtalk                => 0,
        forums_and_responses => \%forums_and_responses,
    );

    is($bot->tls, 0, "gtalk => 0 does not enable TLS");
}

# Test 10: bot is a proper object
{
    my $bot = Net::Jabber::Bot->new(
        server               => 'talk.google.com',
        conference_server     => 'conference.talk.google.com',
        port                 => 5222,
        username             => 'testuser',
        password             => 'testpass',
        alias                => 'testbot',
        gtalk                => 1,
        forums_and_responses => \%forums_and_responses,
    );

    isa_ok($bot, "Net::Jabber::Bot");
}
