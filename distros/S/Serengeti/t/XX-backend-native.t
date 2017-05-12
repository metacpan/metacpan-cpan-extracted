#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

use Serengeti::Backend::Native;

my $backend = Serengeti::Backend::Native->new();

my $got_document_changed_notification = 0;
Serengeti::NotificationCenter->add_observer(
    __PACKAGE__,
    selector => sub { $got_document_changed_notification = 1; },
    for => "DocumentChangedNotification",
);

$backend->get("http://www.google.com");

ok($got_document_changed_notification, "Get posts document changed notification ok");