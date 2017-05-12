#!/usr/bin/perl

# This is the most succinct IRC logger bot script in the history of the universe
# Author: Hinrik Örn Sigurðsson, <hinrik.sig@gmail.com>

use strict;
use warnings;
use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::AutoJoin;
use POE::Component::IRC::Plugin::Logger;

my $nick = 'mylogbot';
my $server = 'irc.blahblah.irc';
my @channels = ('#chan1', '#chan2');
my $path = "$ENV{HOME}/irclogs";

my $irc = POE::Component::IRC::State->spawn(
    Server => $server,
    Nick => $nick,
);
$irc->plugin_add('AutoJoin', POE::Component::IRC::Plugin::AutoJoin->new( Channels => \@channels ));
$irc->plugin_add('Logger', POE::Component::IRC::Plugin::Logger->new( Path => $path ));
$irc->yield('connect');

$poe_kernel->run();
