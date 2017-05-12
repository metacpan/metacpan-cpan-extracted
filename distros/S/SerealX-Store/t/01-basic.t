#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use SerealX::Store;

subtest 'basic constructor' => sub {
	my $st;
	is(exception { $st = SerealX::Store->new() },
		undef, 'new() lives with no arguments');
	ok($st, '... got something back');
	isa_ok($st, 'SerealX::Store', '... of the proper type');
	my $data = {
		a => 1,
		b => 'foo',
		c => [1, 'bar'],
		d => { a => 1, b => 'foo' },
		e => undef,
	};
	my $rand = join('', map(("a".."z","A".."Z","0".."9")[rand 62], 0..7));
	my $path = $ENV{TMPDIR} ? $ENV{TMPDIR}.'/test.'.$rand : '/tmp/test.'.$rand;
	$st->store($data, $path);
	my $decoded = $st->retrieve($path);
	unlink($path);
	is_deeply($decoded, $data, 'data serialization');
};

subtest 'constructor w/ options' => sub {
	my $st;
	is(exception { $st = SerealX::Store->new({
			encoder => { undef_unknown => 1 },
			decoder => { max_recursion_depth => 5 }
		}) }, undef, 'new() lives with both arguments');
	ok($st, '... got something back');
	isa_ok($st, 'SerealX::Store', '... of the proper type');
	isa_ok($st->{'encoder'}, 'Sereal::Encoder', 'encoder init');
	isa_ok($st->{'decoder'}, 'Sereal::Decoder', 'decoder init');
	my $data = {
		a => 1,
		b => 'foo',
		c => [1, 'bar'],
		d => { a => 1, b => 'foo' },
		e => undef,
		f => sub { 1 },
	};
	my $rand = join('', map(("a".."z","A".."Z","0".."9")[rand 62], 0..7));
	my $path = $ENV{TMPDIR} ? $ENV{TMPDIR}.'/test.'.$rand : '/tmp/test.'.$rand;
	$st->store($data, $path);
	my $decoded = $st->retrieve($path);
	unlink($path);
	undef $data->{'f'};
	is_deeply($decoded, $data, 'data serialization');
};

done_testing();
