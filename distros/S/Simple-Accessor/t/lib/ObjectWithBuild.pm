package ObjectWithBuild;

use Simple::Accessor qw{counter};

use Test::More;

my $c = 0;

sub _build_counter {
	++$c;
	note ".... caling _build_counter";
	return $c;
}

1;
