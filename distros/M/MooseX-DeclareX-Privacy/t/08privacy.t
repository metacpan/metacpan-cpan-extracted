use Test::More tests => 13;
use MooseX::DeclareX
	keywords => [qw(class role)],
	plugins  => [qw(private public protected)];
use Test::Fatal;

class Local
{
	private has priv_attr => (
		is      => 'ro',
		isa     => 'Num',
		default => 99,
	);
	private method priv {
		return $self->priv_attr;
	}
	public method pub {
		$self->priv + 1;
	}
	protected method prot {
		return $self->priv + 2;
	}
}

class Local::Sub extends Local
{
	method priv_sub {
		return $self->priv + 3;
	}
	method prot_sub {
		return $self->prot + 4;
	}
}

my $x = Local->new;
my $y = Local::Sub->new;

like exception { $x->priv }, qr{is private};
like exception { $y->priv }, qr{is private};
like exception { $x->prot }, qr{is protected};
like exception { $y->prot }, qr{is protected};
like exception { $y->priv_sub }, qr{is private};

ok !exception { is($x->pub, 100) };
ok !exception { is($y->pub, 100) };
ok !exception { is($y->prot_sub, 105) };

like exception { $x->priv_attr }, qr{is private};
like exception { $y->priv_attr }, qr{is private};
