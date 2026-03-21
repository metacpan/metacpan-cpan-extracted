use strict;
use warnings;
use Test::More;

use Safe;
use Safe::Hole;

# Helper packages for testing object wrapping

{

    package Animal;
    sub new {
        my ( $class, %args ) = @_;
        bless { name => $args{name} || 'unknown', sound => $args{sound} || '...' }, $class;
    }
    sub name  { return $_[0]->{name} }
    sub sound { return $_[0]->{sound} }
    sub speak { return $_[0]->{name} . ' says ' . $_[0]->{sound} }

    sub with_args {
        my ( $self, $prefix, $suffix ) = @_;
        return $prefix . $self->{name} . $suffix;
    }

    sub returns_list {
        my ($self) = @_;
        return ( $self->{name}, $self->{sound} );
    }

    sub dies_on_purpose {
        my ($self) = @_;
        die "intentional error from $self->{name}\n";
    }

    sub DESTROY { }    # explicit no-op to avoid AUTOLOAD dispatch
}

{

    package Dog;
    our @ISA = ('Animal');

    sub new {
        my ( $class, %args ) = @_;
        $args{sound} = 'woof';
        my $self = $class->SUPER::new(%args);
        $self->{tricks} = $args{tricks} || [];
        return $self;
    }

    sub tricks     { return @{ $_[0]->{tricks} } }
    sub trick_count { return scalar @{ $_[0]->{tricks} } }
    sub fetch       { return $_[0]->{name} . ' fetches the ball' }
}

{

    package Counter;
    sub new   { bless { count => 0 }, shift }
    sub inc   { $_[0]->{count}++; return $_[0]->{count} }
    sub value { return $_[0]->{count} }
    sub reset { $_[0]->{count} = 0; return 0 }
}

###################################
# Basic object wrapping
###################################

my $safe = Safe->new;
my $hole = Safe::Hole->new( {} );

my $cat = Animal->new( name => 'Cat', sound => 'meow' );

# Wrap object and share it with the compartment
my $wrapped_cat = $hole->wrap( $cat, $safe, '$cat' );
ok( $wrapped_cat, 'wrap() returns a wrapped object' );
like( ref($wrapped_cat), qr/Safe::Hole/, 'Wrapped object class contains Safe::Hole' );

# Method calls through wrapper via reval
is( $safe->reval('$cat->name()'),  'Cat',            'name() method through wrapped object' );
is( $safe->reval('$cat->sound()'), 'meow',           'sound() method through wrapped object' );
is( $safe->reval('$cat->speak()'), 'Cat says meow',  'speak() method combining fields' );
is( $@,                            '',                'No errors from basic method calls' );

###################################
# Method calls with arguments
###################################

is( $safe->reval('$cat->with_args("[", "]")'), '[Cat]', 'Method with multiple arguments' );
is( $@, '', 'No error from method with arguments' );

###################################
# List context return values
###################################

my @result = $safe->reval('$cat->returns_list()');
is_deeply( \@result, [ 'Cat', 'meow' ], 'Method returning list in list context' );
is( $@, '', 'No error from list-returning method' );

###################################
# Error propagation through wrapped methods
###################################

$safe->reval('$cat->dies_on_purpose()');
like( $@, qr/intentional error from Cat/, 'die in wrapped method propagates to $@' );

###################################
# Calling undefined methods on wrapped objects
###################################

$safe->reval('$cat->nonexistent_method()');
like( $@, qr/(?:nonexistent_method|Can't locate)/i, 'Undefined method on wrapped object sets $@' );

###################################
# Inheritance through wrapping
###################################

my $dog = Dog->new( name => 'Rex', tricks => [ 'sit', 'shake', 'roll' ] );
my $wrapped_dog = $hole->wrap( $dog, $safe, '$dog' );
ok( $wrapped_dog, 'wrap() returns wrapped subclass object' );

# Methods from subclass
is( $safe->reval('$dog->fetch()'), 'Rex fetches the ball', 'Subclass method through wrapper' );
is( $safe->reval('$dog->trick_count()'), 3, 'Subclass method returning count' );
is( $@, '', 'No errors from subclass method calls' );

# Methods inherited from parent
is( $safe->reval('$dog->name()'),  'Rex',            'Inherited method through wrapper' );
is( $safe->reval('$dog->sound()'), 'woof',           'Inherited accessor through wrapper' );
is( $safe->reval('$dog->speak()'), 'Rex says woof',  'Inherited compound method through wrapper' );
is( $@, '', 'No errors from inherited method calls' );

###################################
# Stateful wrapped objects
###################################

my $counter = Counter->new;
$hole->wrap( $counter, $safe, '$counter' );

is( $safe->reval('$counter->value()'), 0, 'Initial counter value' );
is( $safe->reval('$counter->inc()'),   1, 'First increment' );
is( $safe->reval('$counter->inc()'),   2, 'Second increment' );
is( $safe->reval('$counter->value()'), 2, 'Value reflects increments' );
is( $safe->reval('$counter->reset()'), 0, 'Reset returns 0' );
is( $safe->reval('$counter->value()'), 0, 'Value after reset' );
is( $@, '', 'No errors from stateful operations' );

###################################
# wrap() without compartment args (standalone wrapping)
###################################

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $standalone = $hole->wrap( Animal->new( name => 'Fish', sound => 'blub' ) );
    ok( $standalone, 'wrap() without $cpt/$name returns object' );

    # Call methods via hole->call on the standalone wrapper
    is( $hole->call( sub { $standalone->name() } ), 'Fish', 'Standalone wrapped object method works via call()' );

    # Check no warnings were produced
    is( scalar @warnings, 0, 'wrap() without $cpt/$name produces no warnings' )
      or diag("Warnings: @warnings");
}

###################################
# Multiple objects of same class in compartment
###################################

my $safe3 = Safe->new;
my $hole4 = Safe::Hole->new( {} );

my $a1 = Animal->new( name => 'Alpha', sound => 'aaa' );
my $a2 = Animal->new( name => 'Beta',  sound => 'bbb' );
$hole4->wrap( $a1, $safe3, '$a1' );
$hole4->wrap( $a2, $safe3, '$a2' );

is( $safe3->reval('$a1->name()'), 'Alpha', 'First object of same class' );
is( $safe3->reval('$a2->name()'), 'Beta',  'Second object of same class' );
is( $safe3->reval('$a1->sound() . $a2->sound()'), 'aaabbb', 'Both objects independent' );
is( $@, '', 'No errors from multiple objects' );

###################################
# Wrapped code ref (sub wrapping via wrap)
###################################

my $safe4  = Safe->new;
my $hole5  = Safe::Hole->new( {} );
my $greeter = sub { return "hello, $_[0]" };
$hole5->wrap( $greeter, $safe4, '&greet' );

is( $safe4->reval('greet("world")'), 'hello, world', 'Wrapped code ref callable in compartment' );
is( $@, '', 'No error from wrapped code ref' );

###################################
# Error on non-reference argument
###################################

eval { $hole->wrap("not a reference") };
like( $@, qr/reference required/, 'wrap() croaks on non-reference' );

###################################
# Error on type mismatch: code ref with $ sigil
###################################

eval { $hole->wrap( sub { 1 }, $safe, '$bad_name' ) };
like( $@, qr/type mismatch/, 'wrap() croaks on code ref with $ sigil' );

###################################
# Error on object with & sigil
###################################

eval { $hole->wrap( Animal->new(), $safe, '&bad_name' ) };
like( $@, qr/type mismatch/, 'wrap() croaks on object with & sigil' );

###################################
# Error on invalid name format
###################################

eval { $hole->wrap( sub { 1 }, $safe, 'no_sigil' ) };
like( $@, qr/not a valid name/, 'wrap() croaks on name without sigil' );

done_testing();
