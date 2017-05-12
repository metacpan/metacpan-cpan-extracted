#!/usr/bin/env perl -w
use strict;
use Test::Cukes;
use Regexp::Common;
use Regexp::Common::Email::Address;

use Net::Redmine;
require 't/net_redmine_test.pl';

my $r = new_net_redmine();
my $user;

Given qr/the user with id 1 exists/ => sub {
    $r->connection->assert_login;
    $r->connection->get_user_page(id => 1);

    my $content = $r->connection->mechanize->content;
    assert index($content, "Registered on:") > 0;
};

When qr/the user info is crawled/ => sub {
    $user = $r->lookup(user => {id => 1});
};

Then qr/his email should be known/ => sub {
    assert $user->email =~ m/^$RE{Email}{Address}$/;
};

local $/ = undef;
runtests(<DATA>);

__DATA__

Feature: Crawling Redmine User info
  for the good deed

  Scenario: user basic info
    Given the user with id 1 exists
    When the user info is crawled
    Then his email should be known
