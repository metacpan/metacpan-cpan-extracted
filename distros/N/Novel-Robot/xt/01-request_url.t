#!/usr/bin/perl
use utf8;
use lib 'lib';
use Novel::Robot::Browser;
use Test::More ;
use Data::Dump qw/dump/;

my $browser = Novel::Robot::Browser->new();

my $url = 'http://www.jjwxc.net/onebook.php?novelid=2456';
#my $content_get_ref = $browser->request_url_simple($url);
#print $$content_get_ref;
use Novel::Robot;
my $xs = Novel::Robot->new(site => 'Jjwxc', type => 'html');
my $r = $xs->get_book($url);
exit;

my $form_url = 'http://www.jjwxc.net/search.php';
my $post_data = {
    'key1' => 'value1', 
    'key2' => 'value2', 
};
my $content_post_ref = $browser->request_url($form_url, $post_data);
dump($content_post_ref);

done_testing;
