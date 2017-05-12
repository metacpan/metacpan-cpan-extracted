use strict;
use warnings;
use Test::More tests => 4;
use Data::Dumper;

my $positive = MyPositiveEvenInt->new;
$positive->add(2);
is($positive->value, 2, 'add 2');
$positive->add(-2);
is($positive->value, 0, 'add -2');
eval {$positive->add(1) };
ok($@, 'even pre-check in super-class fails appropriately') or diag $@;
eval {$positive->add(-2) };
ok($@, 'positive post-check in super-class fails appropriately') or diag $@, Dumper $positive;
BEGIN {
    package MyEvenInt;

    use MooseX::Contract; # imports Moose for you!
    use Moose::Util::TypeConstraints;

    my $even_int = subtype 'Int', where { $_ % 2 == 0 };

    invariant assert { shift->{value} % 2 == 0 } '$self->{value} must be an even integer';

    has value => (
        is       => 'rw',
        isa      => $even_int,
        required => 1,
        default  => 0
    );

    contract 'add'
        => accepts [ $even_int ]
        => returns void,
        with_context(
            pre => sub { [shift->{value}, shift] },
            post => assert { my $pre = shift; $pre->[0] + $pre->[1] == shift->{value} } 'value must be incremented accurately'
        );
    sub add {
        my $self = shift;
        my $incr = shift;
        $self->{value} += $incr;
        return;
    }

    contract 'get_multiple'
        => accepts ['Int'],
        => returns [$even_int];
    sub get_multiple {
        return shift->{value} * shift;
    }

    no MooseX::Contract;

	package MyPositiveEvenInt;

	use strict;
	use warnings;
	
    use MooseX::Contract; # imports Moose for you!
    use Moose::Util::TypeConstraints;
	extends 'MyEvenInt';
    my $positive_even_int = subtype 'Int', where { $_ >= 0 && $_ % 2 == 0 };
	has '+value' => (
		isa => $positive_even_int
	);
	contract 'add'
		=> pre => assert { shift->{value} + shift >= 0 };

	1;

}

