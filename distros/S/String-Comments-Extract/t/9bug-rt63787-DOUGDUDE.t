#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan tests => 2;

use String::Comments::Extract;

my $re_with_quote = <<'__JS__';
	var re = /"/;
__JS__

my @comments;

lives_ok { @comments = String::Comments::Extract::JavaScript->collect($re_with_quote) }
	'Parse JavaScript with a quote in q regular expression';

ok(@comments == 0, 'No comments');

exit 0;
