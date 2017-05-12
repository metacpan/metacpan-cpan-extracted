use Test::More;

{
    package One::Two::Three;
    use Moo;
    use MooX::ValidateSubs;
    use Types::Standard qw/Str/;

    validate_subs(
        array => { params => [ [Str], [Str, 1], [Str, 1] ] },
    );

    sub array {
        my ($self, @array) = @_;
        return @array;
    }
}

my $maybe = One::Two::Three->new(b => 'ahhhh');

my @list = $maybe->array( 'a', 'b', 'c' );
is_deeply(\@list, [ 'a', 'b', 'c' ], "array returns 3");
my @two  = $maybe->array( 'a', 'b' );
is_deeply(\@two, [ 'a', 'b' ], "array returns 2"); 
eval { $maybe->array };
my $errors = $@;
like( $errors, qr/Error - Invalid count in params for sub - array - expected - 3 - got - 0/, "a list fails");

done_testing();

