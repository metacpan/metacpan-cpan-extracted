use strict;
use Test::More;

my @modules = qw(
    POE::Component::MessageQueue::Client
    POE::Component::MessageQueue::Logger
    POE::Component::MessageQueue::Message
    POE::Component::MessageQueue::Queue
    POE::Component::MessageQueue::Storage::Complex
    POE::Component::MessageQueue::Storage::DBI
    POE::Component::MessageQueue::Storage::FileSystem
    POE::Component::MessageQueue::Storage::Generic::DBI
    POE::Component::MessageQueue::Storage::Generic
    POE::Component::MessageQueue::Storage::Memory
    POE::Component::MessageQueue::Storage::Throttled
    POE::Component::MessageQueue::Storage
    POE::Component::MessageQueue::Subscription
    POE::Component::MessageQueue::Statistics
    POE::Component::MessageQueue::Statistics::Publish::YAML
    POE::Component::MessageQueue::Statistics::Publish
    POE::Component::MessageQueue
    POE::Component::Server::Stomp
);
plan(tests => scalar @modules);
use_ok($_) for @modules;