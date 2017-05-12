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
                                    browser_url => "http://www.google.com/" );

my $a = $sel->get_text("//*");
my $search_query = "Hello World";
$sel->open_ok("/");
$sel->wait_for_page_to_load_ok("30000");
WAIT: {
    for (1..60) {
        if (eval { $sel->is_element_present("btnG") }) { pass; last WAIT }
        sleep(1);
    }
    fail("timeout");
}
pass;
$sel->type_ok("q", $search_query);
#this is a comment
$sel->click_ok("btnG");
$sel->wait_for_page_to_load_ok("30000");
$sel->text_is("link=Hello world program - Wikipedia, the free encyclopedia", "Hello world program - Wikipedia, the free encyclopedia");
$sel->click_ok("link=Hello world program - Wikipedia, the free encyclopedia");
$sel->wait_for_page_to_load_ok("30000");
