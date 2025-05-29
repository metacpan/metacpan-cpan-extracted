#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use Test::More qw( no_plan );
    use Config;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN { use_ok( 'Module::Generic::Iterator' ) || BAIL_OUT( "Unable to load Module::Generic::Iterator" ); }

my $a = Module::Generic::Iterator->new( [qw( John Jack Paul Peter Simon )], { debug => 0 } );

isa_ok( $a, 'Module::Generic::Iterator', 'Iterator object' );
is( $a->length, 5, 'Iterator size' );
is( $a->pos, 0, "Initial iterator position" );
ok( !$a->eof, "Iterator is not at the end of the stack" );
my $elem = $a->find( 'Jack' );
isa_ok( $elem, 'Module::Generic::Iterator::Element', 'Iterator element object' );
is( $elem->value, 'Jack', 'Element value' );
my $not_found = $a->find( 'Bob' );
ok( !defined( $not_found ), 'Element not found is undefined' );
my $first = $a->first;
isa_ok( $first, 'Module::Generic::Iterator::Element', 'First iterator element object' );
is( $first->value, 'John', 'Correct first element value' );
ok( $a->has_next, "Next element exists" );
ok( !$a->has_prev, "No previous element at begining of stack" );
my $last = $a->last;
isa_ok( $last, 'Module::Generic::Iterator::Element', 'Last iterator element object' );
is( $last->value, 'Simon', 'Correct first element value' );
ok( !$a->has_next, "No next element at end of stack" );
ok( $a->has_prev, "Previous element exists" );
is( $a->pos, 4, "Position is at the end of stack" );
$a->pos = 3;
is( $a->pos, 3, "Position set as lvalue" );
$a->reset;
is( $a->pos, 0, "Position is now back at the beginning of stack" );

# Checking Module::Generic::Iterator::Element methods
ok( $first->has_next, "First element has next element" );
ok( !$last->has_next, "Last element has no next element" );
ok( !$first->has_prev, "First element has no next previous" );
ok( $last->has_prev, "Last element has previous element" );
isa_ok( $first->parent, 'Module::Generic::Iterator', 'Element parent object class' );
is( $first->pos, 0, "First element position" );
is( $last->pos, 4, "Last element position" );

subtest 'Additional methods and edge cases' => sub
{
    my $iter = Module::Generic::Iterator->new( [qw( John Jack Paul )], debug => $DEBUG );
    isa_ok( $iter->elements, 'Module::Generic::Array', 'elements class' );
    is( $iter->elements->length, 3, 'elements length' );

    $iter->reset;
    my $elem = $iter->next;
    is( $elem->value, 'John', 'next value' );
    $elem = $iter->next;
    is( $elem->value, 'Jack', 'next value again' );
    $elem = $iter->next;
    is( $elem->value, 'Paul', 'next value last' );
    ok( !defined( $iter->next ), 'next at end' );

    $iter->last;
    $elem = $iter->prev;
    is( $elem->value, 'Jack', 'prev value' );
    $elem = $iter->prev;
    is( $elem->value, 'John', 'prev value first' );
    my $out_of_bound = $iter->prev;
    ok( !defined( $out_of_bound ), 'prev at start' );

    my $empty = Module::Generic::Iterator->new( [], debug => $DEBUG );
    is( $empty->length, 0, 'empty iterator length' );
    ok( $empty->eof, 'empty iterator eof' );
    ok( !defined( $empty->first ), 'empty iterator first' );
    ok( !defined( $empty->last ), 'empty iterator last' );

    $iter->reset;
    eval
    {
        local $SIG{__WARN__} = sub{};
        $iter->pos = "invalid";
    };
    ok( $iter->pos == 0, 'invalid pos assignment' );
};

subtest 'Thread-safe iterator operations' => sub
{
    SKIP:
    {
        if( !$Config{useithreads} )
        {
            skip( 'Threads not available', 2 );
        }

        require threads;
        require threads::shared;

        my @threads = map
        {
            threads->create(sub
            {
                my $tid = threads->tid();
                my $iter = Module::Generic::Iterator->new( [1, 2, 3], debug => $DEBUG );
                while( my $elem = $iter->next )
                {
                    if( $elem->value != 1 && $elem->value != 2 && $elem->value != 3 )
                    {
                        diag( "Thread $tid: Unexpected element value: ", $elem->value ) if( $DEBUG );
                        return(0);
                    }
                }
                return(1);
            });
        } 1..5;

        my $success = 1;
        for my $thr ( @threads )
        {
            $success &&= $thr->join();
        }

        ok( $success, 'All threads iterated successfully' );
        ok( !defined( $Module::Generic::Iterator::DEBUG ) || $Module::Generic::Iterator::DEBUG == 0, 'Global $DEBUG unchanged' );
    };
};

done_testing();

__END__
