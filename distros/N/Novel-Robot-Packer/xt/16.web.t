#!/usr/bin/perl
use utf8;
use lib '../lib';
use Novel::Robot::Packer;
use Novel::Robot;
use Test::More ;
use Data::Dumper;
use utf8;

my $u = 'http://www.jjwxc.net/onebook.php?novelid=2456';
my $xs = Novel::Robot->new(site => $u, type => 'web');
my ($html_ref, $r) = $xs->get_item($u, output=> '123');
done_testing;
