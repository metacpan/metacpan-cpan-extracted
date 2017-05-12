=pod

=encoding utf-8

=head1 PURPOSE

Test that Sub::Block works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Warnings qw( :all );

use Sub::Block;

sub bench
{
	my $coderefs = $_[0];
	my $input    = $_[1] || [];
	my $expected = $_[2];
	
	SKIP: {
		skip 'benchmarking code only runs under $ENV{EXTENDED_TESTING}', scalar(keys %$coderefs)
			unless $ENV{EXTENDED_TESTING};
		
		require Benchmark;
		
		for my $key (sort keys %$coderefs)
		{
			my $code = $coderefs->{$key};
			
			if ($expected)
			{
				local $Test::Builder::Level = $Test::Builder::Level + 1;
				is_deeply(
					[ $code->(@$input) ],
					$expected,
					"implementation '$key' returns expected result",
				);
			}
			
			my $r = Benchmark::timethis(-3, sub { $code->(@$input) }, undef, 'none');
			diag sprintf('%s: %.03f/s', $key, $r->iters / $r->cpu_a);
		}
	}
}

my $blk;
subtest 'Sub::Block creates coderefs ok' => sub
{
	my $foo = 1;
	$blk = block { my ($x) = @_; $foo += $x + $_[1] };
	
	isa_ok($blk, 'Sub::Block');
	
	is($blk->(0, 0.1), 1.1, 'get correct result from executing');
	is($blk->(20, 0.02), 21.12, '$foo was closed over ok');
	is($blk->(300, 0.003), 321.123, '... still ok');
	is($blk->(4000, 0.0004), 4321.1234, '... still ok');
	
	done_testing;
};

subtest 'Sub::Block provides metadata about the coderef' => sub
{
	is_deeply(
		$blk->closures,
		{ '$foo' => \1 },
		'$blk->closures provides the *initial* closed over values',
	);
	like(
		$blk->code,
		qr{\$foo\s*\+=\s*\$x},
		'$blk->code returns the block\'s code',
	);
	done_testing;
};

like(
	$blk->inlinify(qw[ $val1 $val2 ]),
	qr{local\s*\@_\s*=\s*\(\$val1,\s*\$val2\)},
	'$blk->inlinify localizes @_ ok',
);

subtest 'Complex closures with a coderef returning another coderef' => sub
{
	my $foox = 1;
	my $blk = block { my $bar = $foox + 1; sub { return $foox + $bar } };
	isa_ok($blk, 'Sub::Block');
	is(ref($blk->()), 'CODE', 'the block returns a coderef');
	is($blk->()->(), 3, 'the coderef returns correct value');
	done_testing;
};

subtest 'Make a new closure that pipes results' => sub
{
	my $n = 2;
	my $blk = block{$_[0]*$n} >> sub{$_[0]+1} >> block{$_[0]."foo$n"};
	
	is(scalar($blk->(10)), "21foo2", 'call it in scalar context');
	is([$blk->(10)]->[0], "21foo2", 'call it in list context');
	
	done_testing;
};

subtest 'Make a new closure that calls `grep`' => sub
{
	my $n = 2;
	my $blk = block { $_[0] % $n == 0 };
	my $grep1 = $blk->grep;
	my $grep2 = sub { grep { $blk->($_) } @_ };
	my $grep3 = sub { grep $blk->($_), @_ };
	
	isa_ok($grep1, 'Sub::Block');
	
	is_deeply(
		[ $grep1->(3, 5, 2, 1, 4, 10) ],
		[ 2, 4, 10 ],
		'correct results on small input',
	);
	
	bench(
		{
			'Sub::Block'   => $grep1,
			'manual_block' => $grep2,
			'manual_expr'  => $grep3,
		},
		[ 1 .. 10_000 ],
		[ grep $_%2==0, 1 .. 10_000 ],
	);
	
	done_testing;
};

subtest 'Make a new closure that calls `map`' => sub
{
	my $n = 2;
	my $blk = block { $_[0] * $n };
	my $map1 = $blk->map;
	my $map2 = sub { map { $blk->($_) } @_ };
	my $map3 = sub { map $blk->($_), @_ };
	
	isa_ok($map1, 'Sub::Block');
	
	is_deeply(
		[ $map1->(3, 5, 2, 1) ],
		[ 6, 10, 4, 2 ],
		'correct results on small input',
	);
	
	bench(
		{
			'Sub::Block'   => $map1,
			'manual_block' => $map2,
			'manual_expr'  => $map3,
		},
		[ 1 .. 10_000 ],
		[ map $_*2, 1 .. 10_000 ],
	);
	
	done_testing;
};

subtest 'Piping and mapping combined' => sub
{
	my $n = 2;
	my $blk = (block{$_[0]*$n})->map >> sub{map $_+1, @_} >> (block{$_[0]."foo$n"})->map;
	
	is_deeply(
		[ $blk->(10, 5, 100) ],
		[ '21foo2', '11foo2', '201foo2' ],
		'correct results on small input',
	);
	
	done_testing;
};

like(
	warning { block { +return } },
	qr{appears to contain an explicit .return. statement},
	'detects problematic `return` statement',
);

like(
	warning { block { +wantarray } },
	qr{appears to contain an explicit .wantarray. statement},
	'detects problematic `wantarray` statement',
);

done_testing;
