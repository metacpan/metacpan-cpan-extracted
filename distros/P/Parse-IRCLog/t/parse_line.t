#!/usr/bin/perl

use Test::More 'no_plan';
use strict;
use warnings;

use_ok('Parse::IRCLog');

isa_ok(
	my $parser = Parse::IRCLog->new,
	'Parse::IRCLog'
);

is_deeply(
	$parser->parse_line('sdj ;lsdjf asfj asld'),
	{ type => 'unknown', text => 'sdj ;lsdjf asfj asld' },
	"garbage -> unknown"
);

is_deeply(
	$parser->parse_line('< @rjbs > I love this channel!'),
	{ type => 'msg', timestamp => undef, nick_prefix => '@', nick => 'rjbs', text => 'I love this channel!' },
	"boring msg"
);

is_deeply(
	$parser->parse_line(' *  %q[uri] gives rjbs fudge!  '),
	{ type => 'action', timestamp => undef, nick_prefix => '%', nick => 'q[uri]', text => 'gives rjbs fudge!  ' },
	"boring action"
);

is_deeply(
	$parser->parse_line('--- server going down for maintenance!'),
	{ type => 'unknown', text => '--- server going down for maintenance!' },
	"notice"
);

is_deeply(
	$parser->parse_line(undef),
	{ type => 'unknown', text => undef },
	"undef -> unknown"
);

is_deeply(
	$parser->parse_line(''),
	{ type => 'unknown', text => '' },
	"empty -> unknown"
);
