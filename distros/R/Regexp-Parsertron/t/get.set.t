#!/usr/bin/env perl

use v5.10.1;
use strict;
use warnings;

use Regexp::Parsertron;

# Warning: Can't use Test2 or Test::Stream because of the '#' in the regexps.

use Test::More;

# ---------------------

my($re)		= qr/Perl|JavaScript/i;
my($parser)	= Regexp::Parsertron -> new(re => $re);

# Return 0 for success and 1 for failure.

my($result)		= $parser -> parse(re => $re);
my($node_uid)	= 5; # Obtained from displaying and inspecting the tree.

$parser -> append(text => '|C++', uid => $node_uid);

my($count) = 0;

ok($parser -> uid == 6, 'Check uid counts'); $count++;

my(%text) =
(
	1 => '(',
	2 => '?^',
	4 => ':',
	5 => 'Perl|JavaScript|C++',
);

my($text);

for my $uid (sort keys %text)
{
	$text = $parser -> get($uid);

	ok($text{$uid} eq $text, "Check text of uid $uid => '$text'"); $count++;
}

my($new_text) = 'Flub|'; # First Language Under Basic.

$parser -> prepend(text => $new_text, uid => $node_uid);

$text			= $parser -> get($node_uid);
my($expected)	= "${new_text}Perl|JavaScript|C++";

ok($expected eq $text, "Check text of uid $node_uid => '$text'"); $count++;

$new_text = 'BCPL|'; # Basic Combined Programming Language.

$parser -> prepend(text => $new_text, uid => $node_uid);

$text		= $parser -> get($node_uid);
$expected	= "${new_text}Flub|Perl|JavaScript|C++";

ok($expected eq $text, "Check text of uid $node_uid => '$text'"); $count++;

$new_text = 'Algol Lives!';

$parser -> set(text => $new_text, uid => $node_uid);

$text = $parser -> get($node_uid);

ok($new_text eq $text, "Check new text of uid $node_uid => '$text'"); $count++;

my($target)	= 'Algol';
my($found)	= $parser -> find($target);

ok($#$found == 0, "Check that we can find('$target') in some node"); $count++;

print "# Internal test count: $count\n";

done_testing();

