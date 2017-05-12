#!perl
use lib qw( t/lib );
use strict;
use warnings;
use TAP::Parser;
use TAP::Filter::Iterator;
use Test::More tests => 21;
use Test::Deep;
use DeepStuff;

package YayBoo;
use TAP::Filter;
use base qw( TAP::Filter::Iterator );

sub inspect {
    my ( $self, $result ) = @_;
    if ( $result->is_test ) {
        ( my $desc = $result->description ) =~ s/yay/boo/g;
        unless ( $desc eq $result->description ) {
            $desc =~ s/^\s*-\s+//;
            return TAP::Filter->ok( ok => 1, description => $desc );
        }
    }
    return $result;
}

package main;

{
    # Test add_to_parser as a class method
    my $parser
      = TAP::Parser->new( { source => [ '1..1', 'ok 1 - yay', ] } );
    YayBoo->add_to_parser( $parser );
    my @got = ();
    while ( defined( my $result = $parser->next ) ) {
        push @got, $result;
    }
    cmp_deeply [@got], [ is_plan( 1 ), is_test( 1, 'boo', 1 ) ],
      "yay -> boo";
}

{
    # Assorted error messages
    my $yayboo = YayBoo->new;
    eval { $yayboo->inspect_hook( 'foo' ) };
    like $@, qr{inspect\s+must\s+be\s+a\s+coderef}i,
      "coderef type error";

    for my $iterator ( undef, [], TAP::Filter->ok ) {
        eval { $yayboo->next_iterator( $iterator ) };
        like $@, qr{Iterator \s+ must \s+ have \s+ a \s+ 'tokenize' \s+
            method}ix, "iterator type error";
    }

    for my $parser ( [], TAP::Filter->ok ) {
        eval { $yayboo->parser( $parser ) };
        like $@, qr{parser\s+must\s+be\s+a\s+TAP::Parser}i,
          "parser type error";
    }
}

{
    # A result with no raw field
    my $test = TAP::Filter->ok;
    $test->_number( 7 );
    delete $test->{raw};
    TAP::Filter::Iterator::_set_test_number( $test, 19 );
    is $test->number, 19, "no raw";
}

{
    # A non-existent iterator class
    eval { TAP::Filter->add_filter( 'IHopeThisClassDoesNotExist' ) };
    like $@, qr{Can't \s+ load \s+ filter \s+ class \s+ for \s+
        IHopeThisClassDoesNotExist}ix, "filter not found";
}

{
    # A non-existent iterator class
    for my $filter ( undef, [], 'TAP::Filter', TAP::Filter->ok ) {
        eval { TAP::Filter->add_filter( $filter ) };
        like $@,
          qr{Filter \s+ must \s+ have \s+ a \s+ 'add_to_parser' \s+
            method}ix, "not a filter";
    }
}

{
    # ok method
    my @cases = (
        {
            name   => 'empty',
            args   => [],
            expect => is_test( 0, '', 0 ),
        },
        {
            name  => 'bad args',
            args  => [ 0, ],
            error => qr{ok \s+ needs \s+ a \s+ number \s+ of \s+ name
                \s+ => \s+ value \s+ pairs}ix,
        },
        {
            name => 'description',
            args => [ description => 'foo', ok => 1, ],
            expect => is_test( 0, 'foo', 1 ),
        },
        {
            name => 'no number',
            args => [ description => 'seventeen', number => 17, ],
            expect => is_test( 0, 'seventeen', 0 ),
        },
        {
            name   => 'skip',
            args   => [ description => 'skippy', directive => 'skip', ],
            expect => all(
                is_test( 0, 'skippy', 0 ),
                methods( directive => 'SKIP' )
            ),
        },
        {
            name => 'skip, reason',
            args => [
                description => 'skippy',
                directive   => 'skip',
                explanation => 'bored',
            ],
            expect => all(
                is_test( 0, 'skippy', 0 ),
                methods( directive => 'SKIP', explanation => 'bored' )
            ),
        },
        {
            name   => 'todo',
            args   => [ description => 'later', directive => 'todo', ],
            expect => all(
                is_test( 0, 'later', 0 ),
                methods( directive => 'TODO' )
            ),
        },
        {
            name => 'todo, reason',
            args => [
                description => 'later',
                directive   => 'todo',
                explanation => 'lazy',
            ],
            expect => all(
                is_test( 0, 'later', 0 ),
                methods( directive => 'TODO', explanation => 'lazy' )
            ),
        },
    );

    for my $case ( @cases ) {
        my $name = 'TAP::Filter->ok (' . $case->{name} . ')';
        my $result
          = eval { TAP::Filter->ok( @{ $case->{args} || [] } ) };
        if ( my $expect = $case->{expect} ) {
            cmp_deeply $result, $expect, "$name: result";
        }
        elsif ( my $error = $case->{error} ) {
            like $@, $error, "$name: error";
        }
        else {
            fail "Bad test";
        }
    }
}
