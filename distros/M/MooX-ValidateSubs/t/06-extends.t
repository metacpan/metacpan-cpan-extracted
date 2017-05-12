use Test::More;

{
    package One::Two::Three;
    use Moo;
    use MooX::ValidateSubs;
    use Types::Standard qw/Str/;

    validate_subs(
        hash => { 
            params => {
                one => [Str, sub { 'Hello World' }], 
                two => [Str, 'build_two' ], 
                three => [Str],
            },
        }
    );

    sub build_two {
        return 'Goodbye World';
    }

    sub hash {
        my ($self, %array) = @_;
        return %array;
    }
}

{
    package One::Two::Three::Four;
    use Moo;
    use MooX::ValidateSubs;
    use Types::Standard qw/Str/;

    extends 'One::Two::Three';

    validate_subs(
        '+hash' => { 
            params => {
                one => [Str, sub { 'Hello World' }], 
                two => [Str, 'build_two' ], 
                three => [Str],
                four => [Str],
            },
        }
    );
}

my $maybe = One::Two::Three::Four->new();
my %list = $maybe->hash( three => 'ahhhh', four => 'should we merge' );
is_deeply(\%list, { 
    one => 'Hello World', 
    two => 'Goodbye World', 
    three => 'ahhhh', 
    four => 'should we merge' 
}, "list returns 3 key/value pairs" );

eval { $maybe->hash };
my $errors = $@;
like( $errors, qr/Undef did not pass type constraint "Str"/, "a list fails");

done_testing();

