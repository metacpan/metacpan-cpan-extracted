use Test::More;

{
    package One::Two::Three;
    use Moo;
    use MooX::ValidateSubs;
    use Types::Standard qw/Str/;

    has thing => (
        is => 'ro',
        default => sub { return 'a b c'; }
    );
    
    validate_subs(
        hash => { 
            params => {
                one => [Str, sub { 'Hello World' }], 
                two => [Str, 'build_two' ], 
                three => [Str],
            },
            returns => {
                one => [Str, sub { 'Hello World' }], 
                two => [Str, 'build_two' ], 
                three => [Str],
                four => [Str],
            }
        }
    );

    sub build_two {
        return 'Goodbye World';
    }

    sub hash {
        my ($self, %hash) = @_;
        $hash{four} = $self->thing;
        return %hash;
    }
}

{
    package One::Two::Three::Four;
    use Moo;
    use MooX::ValidateSubs;
    use Types::Standard qw/Str/;

    extends 'One::Two::Three';

    around hash => sub {
        my ($orig, $self, %hash) = @_;
        $hash{four} = { no => 'validation happens' };
        return %hash;
    };
}

{
    package One::Two::Three::Five;
    use Moo;
    use MooX::ValidateSubs;
    use Types::Standard qw/Str/;

    extends 'One::Two::Three';

    around hash => sub {
        my ($orig, $self, %hash) = @_;
        %hash = $self->$orig(%hash);
        $hash{four} = { no => 'validation happens here' };
        return %hash;
    };
}

{
    package One::Two::Three::Six;
    use Moo;
    use MooX::ValidateSubs;
    use Types::Standard qw/Str/;

    extends 'One::Two::Three';

    around hash => sub {
        my ($orig, $self, %hash) = @_;
        $hash{four} = { yes => 'this gets validated' };
        %hash = $self->$orig(%hash);
        return %hash;
    };
}

{
    package One::Two::Three::Seven;
    use Moo;
    use MooX::ValidateSubs;
    use Types::Standard qw/Str/;

    has thing => (
        is => 'ro',
        default => sub { return 'a b c'; }
    );
    
    validate_subs(
        hash => { 
            params => {
                one => [Str, sub { 'Hello World' }], 
                two => [Str, 'build_two' ], 
                three => [Str],
            },
            returns => {
                one => [Str, sub { 'Hello World' }], 
                two => [Str, 'build_two' ], 
                three => [Str],
                four => [Str],
            }
        }
    );

    sub build_two {
        return 'Goodbye World';
    }

    sub hash {
        my ($self, %hash) = @_;
        $hash{four} = $self->thing;
        return %hash;
    }

    around hash => sub {
        my ($orig, $self, %hash) = @_;
        $hash{four} = { yes => 'this gets validated' };
        %hash = $self->$orig(%hash);
        return %hash;
    };
}

{
    package One::Two::Three::Eight;
    use Moo;
    use MooX::ValidateSubs;
    use Types::Standard qw/Str/;

    has thing => (
        is => 'ro',
        default => sub { return 'a b c'; }
    );
    
    validate_subs(
        hash => { 
            params => {
                one => [Str, sub { 'Hello World' }], 
                two => [Str, 'build_two' ], 
                three => [Str],
            },
            returns => {
                one => [Str, sub { 'Hello World' }], 
                two => [Str, 'build_two' ], 
                three => [Str],
                four => [Str],
            }
        }
    );

    sub build_two {
        return 'Goodbye World';
    }

    sub hash {
        my ($self, %hash) = @_;
        $hash{four} = $self->thing;
        return %hash;
    }

    around hash => sub {
        my ($orig, $self, %hash) = @_;
        %hash = $self->$orig(%hash);
        $hash{four} = { no => 'validation happens here' };
        return %hash;
    };

}


my $maybe = One::Two::Three->new();
my %list = $maybe->hash( three => 'ahhhh' );
is_deeply(\%list, { 
    one => 'Hello World', 
    two => 'Goodbye World', 
    three => 'ahhhh', 
    four => 'a b c' 
}, "list returns 4 key/value pairs" );

my $testing = One::Two::Three::Four->new();
my %list2 = $testing->hash( three => 'ahhhh' );
is_deeply(\%list2, { 
    three => 'ahhhh',
    four => { no => 'validation happens' },
}, "list returns 4 key/value pairs" );

my $five = One::Two::Three::Five->new();
my %list = $five->hash( three => 'ahhhh' );
is_deeply(\%list, { 
    one => 'Hello World', 
    two => 'Goodbye World', 
    three => 'ahhhh', 
    four => { no => 'validation happens here' }, 
}, "list returns 4 key/value pairs" );

my $six = One::Two::Three::Six->new();
eval { $six->hash( three => 'ahhhh' ) };
my $errors = $@;
like( $errors, qr/Error in params - An illegal passed key - four -/, "four is currently not a valid param");

my $seven = One::Two::Three::Seven->new();
eval { $seven->hash( three => 'ahhhh' ) };
my $errors = $@;
like( $errors, qr/Error in params - An illegal passed key - four -/, "four is currently not a valid param");

my $eight = One::Two::Three::Eight->new();
my %list8 = $eight->hash( three => 'ahhhh' );
is_deeply(\%list8, { 
    one => 'Hello World', 
    two => 'Goodbye World', 
    three => 'ahhhh', 
    four => { no => 'validation happens here' }, 
}, "list returns 4 key/value pairs" );


done_testing();

