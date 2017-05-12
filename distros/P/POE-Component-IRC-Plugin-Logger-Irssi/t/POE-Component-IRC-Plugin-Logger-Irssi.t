#!/usr/bin/perl
use v5.14;
use strict;
use warnings;

use Test::More tests => 14;
BEGIN { use_ok('POE::Component::IRC::Plugin::Logger::Irssi', 'irssi_format') };

my $fmt = irssi_format;
my $localtime0 = localtime 0;
is $fmt->{'+b'}->('mgv', '*!root@*'), '-!- mode [+b *!root@*] by mgv', 'mode +b';
is $fmt->{nick_change}->('mgv', 'arachnidsGrip'), '-!- mgv is now known as arachnidsGrip', 'change nick';
is $fmt->{topic_is}->('#chan', 'wasting time'), '-!- Topic for #chan: wasting time', 'see topic';
is $fmt->{topic_change}->('mgv', 'doing nothing'), '-!- mgv changed the topic to: doing nothing', 'set topic';
is $fmt->{topic_change}->('mgv', ''), '-!- Topic unset by mgv', 'unset topic';
is $fmt->{privmsg}->('mgv', 'Hello, world!'), '<mgv> Hello, world!', 'privmsg';
is $fmt->{notice}->('mgv', 'Hello, world!'), '-mgv- Hello, world!', 'notice';
is $fmt->{action}->('mgv', 'says hello'), '* mgv says hello', 'action';
is $fmt->{join}->('mgv', 'marius@example.org', '#chan'), '-!- mgv [marius@example.org] has joined #chan', 'join';
is $fmt->{part}->('mgv', 'marius@example.org', '#chan', 'bye'), '-!- mgv [marius@example.org] has left #chan [bye]', 'part';
is $fmt->{quit}->('mgv', 'marius@example.org', 'buh-bye'), '-!- mgv [marius@example.org] has quit [buh-bye]', 'quit';
is $fmt->{kick}->('mgv', 'troll', '#chan', 'trolling'), '-!- troll was kicked from #chan by mgv [trolling]', 'kick';
is $fmt->{topic_set_by}->('#chan', 'mgv', 0), "-!- Topic set by mgv [$localtime0]";
