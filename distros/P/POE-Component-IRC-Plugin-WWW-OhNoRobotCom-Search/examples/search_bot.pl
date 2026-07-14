#!/usr/bin/env perl

use strict;
use warnings;
# sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use lib '../lib';
use POE qw(Component::IRC
Component::IRC::Plugin::WWW::OhNoRobotCom::Search);

my $irc = POE::Component::IRC->spawn(
    nick        => 'OhNoRobotComBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'Bot for searching ohnorobot.com',
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001  irc_ohnorobot_results) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'OhNoRobot' =>
            POE::Component::IRC::Plugin::WWW::OhNoRobotCom::Search->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
}

sub irc_ohnorobot_results {
    use Data::Dumper;
    print Dumper $_[ARG0];
}