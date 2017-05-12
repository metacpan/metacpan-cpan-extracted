# $Id: 10pod.t 459 2006-05-19 19:26:42Z nicolaw $

use strict;
use Test::More;
eval "use Test::Deep";
if ($@) { plan skip_all => "Test::Deep required for testing parse_lin()"; }
else { plan tests => 4; }

use lib qw(./lib ../lib);
use Parse::Colloquy::Bot qw(:all);
 
for my $data (_data()) {
	cmp_deeply(
			parse_line($data->{raw}),
			$data,
			$data->{raw},
		);
}

sub _data {
	my @data = (
		{         args =>
			  ['HELLO', 'colloquy', '1.41.94.arwen-1', '(09', 'May', '2006)'],
			cmdargs => undef,
			command => undef,
			list    => undef,
			msgtype => 'HELLO',
			person  => undef,
			raw     => 'HELLO colloquy 1.41.94.arwen-1 (09 May 2006)',
			respond => undef,
			text    => 'colloquy 1.41.94.arwen-1 (09 May 2006)',
			time    => ignore(),
		},

		{         args => [
				'RAW',      '+++',  'For', 'an',
				'account,', 'talk', 'to',  'a',
				'master.',  'You',  'can', 'get',
				'a',        'list', 'of',  'available',
				'commands'
			],
			cmdargs => undef,
			command => undef,
			list    => undef,
			msgtype => 'RAW',
			person  => undef,
			raw     =>
			  'RAW +++ For an account, talk to a master. You can get a list of available commands',
			respond => undef,
			text    =>
			  '+++ For an account, talk to a master. You can get a list of available commands',
			time => ignore(),
		},

		{         args => ['LOOKHDR', 'Active', 'users', 'in', 'group', 'Bots-R-Us:'],
			cmdargs => undef,
			command => undef,
			list    => undef,
			msgtype => 'LOOKHDR',
			person  => undef,
			raw     => 'LOOKHDR Active users in group Bots-R-Us:',
			respond => undef,
			text    => 'Active users in group Bots-R-Us:',
			time    => ignore(),
		},

		{         args    => ['COMMENT', 'No', 'comments', 'set.'],
			cmdargs => undef,
			command => undef,
			list    => undef,
			msgtype => 'COMMENT',
			person  => undef,
			raw     => 'COMMENT No comments set.',
			respond => undef,
			text    => 'No comments set.',
			time    => ignore(),
		});

	return @data;
}

1;

