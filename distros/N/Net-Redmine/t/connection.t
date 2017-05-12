#!/usr/bin/env perl -w
use strict;
use Test::Cukes;
use Net::Redmine;
use URI;
require 't/net_redmine_test.pl';

my ($r, $c);

Given qr/an redmine object/ => sub {
    $r = new_net_redmine();
    $c = $r->connection;

    assert $c->isa("Net::Redmine::Connection");
};

When qr/invoke the "(.*)" method/ => sub {
    $c->$1;
};

Then qr/it should be on the login page/ => sub {
    my $uri = URI->new($c->mechanize->uri);
    my $content = $c->mechanize->content;

    assert $uri->path eq "/login";
    assert $content =~ /id="login-form"/;
};

Then qr/it should be signed in/ => sub {
    $c->get_project_overview;
    my $link = $c->mechanize->find_link( url_regex => qr[/my/page] );
    assert $link;
};

$/ = undef;
feature(<DATA>);
runtests;

__END__
Feature: Net::Redmine::Connection class
  Describe the features provided by Net::Redmine::Connection class

  Scenario: test the get_login_page method
    Given an redmine object
    When invoke the "get_login_page" method
    Then it should be on the login page

  Scenario: test the assert_login method
    Given an redmine object
    When invoke the "assert_login" method
    Then it should be signed in
