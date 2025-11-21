use strict;
use warnings;
use Test::More;
{ package Local::Dummy1; use Test::Requires 'Moo' };

{

    package TestAfter;
    use Moo;
    use Sub::HandlesVia;

    # create some wrappers; split things useful to Sub::HandlesVia
    # across wrappers. This only works if they are run after
    # Sub::HandlesVia, so that they wrap the has() function wrapped
    # by Sub::HandlesVia

    around has => sub {
        my $orig = shift;
        $orig->( @_, handles_via => 'Array' );
    };

    around has => sub {
        my $orig = shift;
        $orig->( @_, handles => { 'push' => 'push...' } );
    };

    # these are here just to create some extra wrappers
    for ( 1 .. 5 ) {
        before has => sub { };
        after has => sub { };
    }

    has test => ( is => 'ro' );

}

my $obj = TestAfter->new;
is_deeply( $obj->push('a')->push('test')->test, [qw(a test)] );

{

    package TestBefore;
    use Moo;

    BEGIN {

        # create some wrappers; split things useful to Sub::HandlesVia
        # across wrappers.

        # these are here just to create some extra wrappers
        for ( 1 .. 5 ) {
            before has => sub { };
            after has => sub { };
        }

        # this depends upon a later modified has
        around has => sub {
            my ($orig, $attr, %opt ) = @_;
            my @countdown = reverse @{$opt{default}->()};

            $opt{default} = sub { \@countdown };
            $orig->( $attr, %opt );
        };
    }

    # modify the has that has been modfiied
    use Sub::HandlesVia;

    around has => sub {
        my $orig = shift;
        $orig->( @_, handles => { 'push' => 'push...' } );
    };

    around has => sub {
        my $orig = shift;
        $orig->( @_, handles_via => 'Array' );
    };

    around has => sub {
        my $orig = shift;
        $orig->( @_, default => sub { [ 1, 2, 3 ] } );
    };

    has test => ( is => 'ro' );

}

$obj = TestBefore->new;
is_deeply( $obj->test, [qw( 3 2 1 )] );

is_deeply( $obj->push('blast')->push('off')->test, [qw(3 2 1 blast off)] );

done_testing;
