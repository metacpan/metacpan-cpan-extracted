#!/usr/bin/perl
use utf8;
use lib '../lib';
use Novel::Robot::Parser;
use Test::More ;
use Data::Dumper;

## {{{ jjwxc
my $pr = Novel::Robot::Parser->new(site=>'jjwxc');

my $index_url = 'http://www.jjwxc.net/onebook.php?novelid=2456';

my $writer_url = "http://www.jjwxc.net/oneauthor.php?authorid=3243";
my ($writer_name, $writer_ref) = $pr->get_board_ref($writer_url);
is($writer_name eq '顾漫' ? 1 : 0, 1, 'board writer_name');
my $cnt = grep { $_->{url} eq $index_url } @$writer_ref;
is($cnt, 1, 'board writer_book');
## }}}

done_testing;
