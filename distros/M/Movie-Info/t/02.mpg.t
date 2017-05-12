use strict;
use Test::More;
use Movie::Info;

my $mi = eval { Movie::Info->new };
if ($@ || !defined $mi) {
	plan skip_all => 'No mplayer installed';
} else {
	plan tests => 5;
}

my %info;
ok(%info = $mi->info('t/files/test.mpg'), 'Read info from file ok');
is($info{filename}, 't/files/test.mpg', 'Got filename');
is($info{width}, 381, 'Got width');
is($info{height}, 382, 'Got height');
is(int($info{fps}), 25, 'Got fps');

