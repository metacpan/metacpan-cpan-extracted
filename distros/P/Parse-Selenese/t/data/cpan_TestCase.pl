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
                                    browser_url => "http://www.yahoo.co.jp/" );

$sel->open_ok("/");
$sel->title_is("Yahoo! JAPAN");
$sel->type_ok("srchtxt", "cpan");
$sel->click_ok("srchbtn");
$sel->wait_for_page_to_load_ok("30000");
$sel->title_is("「cpan」の検索結果 - Yahoo!検索");
$sel->click_ok("//div[\@id='WS2m']/ul/li[1]/div[1]/h3/a/b");
$sel->wait_for_page_to_load_ok("30000");
$sel->title_is("CPAN");
$sel->click_ok("link=Perl modules");
$sel->wait_for_page_to_load_ok("30000");
$sel->title_is("CPAN/modules");
$sel->click_ok("link=CPAN Search");
$sel->wait_for_page_to_load_ok("30000");
$sel->title_is("The CPAN Search Site - search.cpan.org");
$sel->type_ok("query", "Test::More");
$sel->select_ok("mode", "label=Modules");
$sel->click_ok("//input[\@value='CPAN Search']");
$sel->wait_for_page_to_load_ok("30000");
$sel->title_is("The CPAN Search Site - search.cpan.org");
$sel->click_ok("//body[\@id='cpansearch']/h2[1]/a/b");
$sel->wait_for_page_to_load_ok("30000");
$sel->title_is("Test::More - search.cpan.org");
$sel->is_text_present_ok("Test::More");
