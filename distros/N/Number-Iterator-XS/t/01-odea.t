use Test::More;

use Number::Iterator::XS;

my $iter = Number::Iterator::XS->new(interval => 50);

$iter++;

is("$iter", 50);

$iter--;

is("$iter", 0);

$iter++;

$iter++;

is("$iter", 100);

$iter = Number::Iterator::XS->new(
	interval => 2,
	iterate => sub {
		my ($self) = @_;
		($self->{value} ||= 1) *= $self->{interval};
	},
	deiterate => sub {
		my ($self) = @_;
		$self->{value} /= $self->{interval};
	}
);

$iter++;

is("$iter", 2);

$iter++;

is("$iter", 4);

$iter++;

is("$iter", 8);

$iter--;

is("$iter", 4);

done_testing();
