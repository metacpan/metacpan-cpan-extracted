package Odea;
use Moo;
use MooX::Keyword {
	thing => {
		builder => sub {
			my ($moo, $keyword, %params) = @_;
			$moo->has(
				$keyword,
				%{\%params}
			);
		}
	}
};

thing okay => (
	is => 'ro',
	default => sub { return 1; }
);

thing other => (
	is => 'ro',
	default => sub { return 2; }
);

1;

