use Test::More;

{
    package One::Two::Three;
    use Moo;
    use MooX::ValidateSubs;
    use Types::Standard qw/Str HashRef/;

    validate_subs(
        hash => { 
            params => {
                one => [Str, sub { 'Hello World' }], 
                two => [Str, 'build_two' ],
            },
            returns => {
                one   => [Str], 
                two   => [Str],
                three => [Str],
                four  => [Str, 'why_not'],
                five  => [HashRef, sub { {one => 'two'} }],
            }
        }
    );

    sub build_two {
        return 'Goodbye World';
    }

    sub why_not {
        return 'I live in my own world';
    }

    sub hash {
        my ($self, %hash) = @_;
        $hash{three} = 'Add a value';
        return %hash;
    }
}

my $maybe = One::Two::Three->new();

my %list = $maybe->hash();
is_deeply(\%list, { 
    one => 'Hello World', 
    two => 'Goodbye World', 
    three => 'Add a value', 
    four => 'I live in my own world', 
    five => { one => 'two' } 
}, "list returns 5 key/value pairs");

my %over = $maybe->hash( one => 'can be set', two => 'can be set' );
is_deeply(\%over, {
    one => 'can be set', 
    two => 'can be set', 
    three => 'Add a value', 
    four => 'I live in my own world', 
    five => { one => 'two' } 
}, "list returns 5 key/value pairs");

eval { $maybe->hash( three => 'cannot be set' ) };
my $errors = $@;
like( $errors, qr/Unrecognized parameter: three/, "a list fails");

done_testing();
