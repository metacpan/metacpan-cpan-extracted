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
                four => [Str, 1],
            },
        }
    );

    sub build_two {
        return 'Goodbye World';
    }

    sub hash {
        my ($self, %hash) = @_;
        return %hash;
    }
}

{
    package One::Two::Three::Redefine;
    use Moo;
    use MooX::ValidateSubs;
    use Types::Standard qw/Str/;
    
    extends 'One::Two::Three';

    sub hash {
        my ($self, %hash) = @_;
        return %hash;
    }
}

{
    package One::Two::Three::RedefineWithValidation;
    use Moo;
    use MooX::ValidateSubs;
    use Types::Standard qw/Str/;
    
    extends 'One::Two::Three';

    validate_subs(
        hash => { 
            params => {
                one => [Str, sub { 'Hello World' }], 
                two => [Str, 'build_two' ], 
                three => [Str],
                four => [Str, 1],
            },
        }
    );

    sub hash {
        my ($self, %hash) = @_;
        return %hash;
    }
}



my $maybe = One::Two::Three::Redefine->new();

my %list = $maybe->hash( three => 'ahhhh' );
is_deeply(\%list, { three=>  'ahhhh' }, "list returns 1 key/value pairs");

my $reValidation = One::Two::Three::RedefineWithValidation->new();
my %valid = $reValidation->hash( three => 'ahhhh' );
is_deeply(\%valid, { one => 'Hello World', two => 'Goodbye World', three=>  'ahhhh' }, "list returns 3 key/value pairs");

done_testing();

