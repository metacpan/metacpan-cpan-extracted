use strict;
use warnings;
use Test::More tests => 2;

my $m = MyEvenInt->new;
eval { $m->add(2) };
ok(!$@, 'with_context assertion successful') or diag $@;
is($m->value, 2, 'incremented correctly');

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

}
