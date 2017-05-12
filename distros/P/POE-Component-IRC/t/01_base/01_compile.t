use strict;
use warnings FATAL => 'all';
use Test::More;

my @modules = qw(
    POE::Filter::IRC
    POE::Filter::IRC::Compat
    POE::Component::IRC
    POE::Component::IRC::State
    POE::Component::IRC::Qnet
    POE::Component::IRC::Qnet::State
    POE::Component::IRC::Constants
    POE::Component::IRC::Common
    POE::Component::IRC::Plugin
    POE::Component::IRC::Plugin::Whois
    POE::Component::IRC::Plugin::Proxy
    POE::Component::IRC::Plugin::PlugMan
    POE::Component::IRC::Plugin::NickServID
    POE::Component::IRC::Plugin::NickReclaim
    POE::Component::IRC::Plugin::Logger
    POE::Component::IRC::Plugin::ISupport
    POE::Component::IRC::Plugin::FollowTail
    POE::Component::IRC::Plugin::Console
    POE::Component::IRC::Plugin::Connector
    POE::Component::IRC::Plugin::CTCP
    POE::Component::IRC::Plugin::CycleEmpty
    POE::Component::IRC::Plugin::BotTraffic
    POE::Component::IRC::Plugin::BotAddressed
    POE::Component::IRC::Plugin::AutoJoin
    POE::Component::IRC::Plugin::BotCommand
);

plan tests => scalar @modules;
use_ok($_) for @modules;

