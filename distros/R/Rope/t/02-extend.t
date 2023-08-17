use Test::More;

{
	package One;

	use Rope;

	prototyped (
		one => sub {
			$_[1] ? $_[1] : $_[0]->{two}();	
		},
		two => sub {
			return 50;
		}
	);

	1;
}

{
	package Two;

	use Rope;

	extends 'One';

	prototyped (
		three => sub {
			return 100;
		}
	)
}

my $one = One->new;

is($one->{one}(), 50);
is($one->{one}(10), 10);

my $two = Two->new;
is($two->{two}(), 50);
is($two->{three}(), 100);

done_testing();
