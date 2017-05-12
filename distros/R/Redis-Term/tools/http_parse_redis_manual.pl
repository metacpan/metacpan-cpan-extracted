#!/usr/bin/perl

=pod

http.pl

Author: Chen Gang
Blog: http://blog.yikuyiku.com
Corp: SINA
At 2014-02-26 Beijing

=cut


use strict;
use warnings;
use Data::Dump qw/ddx dump/;
use HTML::TreeBuilder 5 -weak; 
 
my $file_name = shift;
my $tree = HTML::TreeBuilder->new; 
$tree->parse_file($file_name);
my @li = $tree->find_by_tag_name('li');
my %redis;
my $count;

foreach (@li)
{
	$count++;
	my $group = $_->attr_get_i('data-group');
	my $summary = $_->find_by_attribute('class', 'summary')->as_text();
	my $name = lc($_->find_by_tag_name('a')->as_text());
	$redis{$group}{$name} = $summary;
}

print dump(%redis);

