#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

BEGIN { use_ok("Serengeti::NotificationCenter") };

ok(Serengeti::NotificationCenter->default_center);

lives_ok {
    Serengeti::NotificationCenter->add_observer(
        0, 
        selector => sub {}, 
    );
};

my $target = "FooBar";
my ($self, $sender, $notification, $data);
Serengeti::NotificationCenter->add_observer(
    $target, selector => sub {
        ($self, $sender, $notification, $data) = @_;        
    }
);

Serengeti::NotificationCenter->post_notification(undef, "TestNotification");
is($self, $target);
ok(!defined $sender);
is($notification, "TestNotification");
ok(!defined $data);