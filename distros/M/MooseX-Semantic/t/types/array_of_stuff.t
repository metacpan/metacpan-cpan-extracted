use Test::More;
use Data::Dumper;
use RDF::Trine qw(literal);
use Test::Moose;

sub array_of_literals {
    {
        package AOL;
        use Moose;
        use MooseX::Semantic::Types qw(ArrayOfTrineLiterals);
        has aol => (
            is => 'rw',
            traits => ['Array'],
            isa => ArrayOfTrineLiterals,
            default => sub { [] },
            coerce => 1,
        );
    }
    my $aol = AOL->new( aol => [ 'foo', literal('bar') ] );
    for (@{$aol->aol}) {
        isa_ok $_, 'RDF::Trine::Node::Literal';
    }
    is $aol->aol->[0]->literal_value, 'foo';
    is $aol->aol->[1]->literal_value, 'bar';
    warn Dumper $aol;
}

&array_of_literals;

done_testing;
