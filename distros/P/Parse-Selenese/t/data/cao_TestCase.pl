#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw(sleep);
use Test::WWW::Selenium;
use Test::More "no_plan";
use Test::Exception;
use utf8;

my $sel = Test::WWW::Selenium->new( host => "localhost",
                                    port => 4444,
                                    browser => "*firefox",
                                    browser_url => "http://www.google.co.jp/" );

$sel->open_ok("/");
$sel->title_is("Google");
$sel->click_ok("link=検索オプション");
$sel->wait_for_page_to_load_ok("30000");
$sel->title_is("Google 検索オプション");
$sel->type_ok("as_q", "内閣府");
$sel->select_ok("num", "label=100 件");
$sel->select_ok("lr", "label=日本語");
$sel->click_ok("btnG");
$sel->wait_for_page_to_load_ok("30000");
$sel->title_is("内閣府 - Google 検索");
$sel->click_ok("link=内閣府ホームページ");
$sel->wait_for_page_to_load_ok("30000");
$sel->title_is("内閣府ホームページ");
