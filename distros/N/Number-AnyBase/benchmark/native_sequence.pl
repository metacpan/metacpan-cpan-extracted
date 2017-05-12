#!perl

use strict;
use warnings;

use Benchmark qw(cmpthese);

use Number::AnyBase;

use constant {
    START_DEC        => 1_000_000_000,
    SEQ_LENGTH       => 20_000,
    TEST_REPETITIONS => 50
};

$| = 1;

my @alphabet = ( 0..9, 'A'..'Z', 'a'..'z' );
my $conv = Number::AnyBase->new(@alphabet);

my $base_num = $conv->to_base(START_DEC);

print 'Unary increment vs conversions roundtrip', "\n";
cmpthese( TEST_REPETITIONS, {
    'Native unary increment' => sub {
        my $next = $base_num;
        $next = $conv->next($next) for 1..SEQ_LENGTH
    },
    'Unary increment with conversion' => sub {
        my $next = $base_num;
        $next = $conv->to_base( $conv->to_dec($next) + 1 ) for 1..SEQ_LENGTH
    }
});

print "\n";

print 'Unary decrement vs conversions roundtrip', "\n";
cmpthese( TEST_REPETITIONS, {
    'Native unary decrement' => sub {
        my $next = $base_num;
        $next = $conv->prev($next) for 1..SEQ_LENGTH
    },
    'Unary decrement with conversion' => sub {
        my $next = $base_num;
        $next = $conv->to_base( $conv->to_dec($next) - 1 ) for 1..SEQ_LENGTH
    }
});

print "\n";

print 'Native sequence vs to_base() only', "\n";
cmpthese( TEST_REPETITIONS, {
    'Native sequence' => sub {
        my $next = $base_num;
        $next = $conv->next($next) for 1..SEQ_LENGTH
    },
    'Sequence with to_base()' => sub {
        my $dec_num = $conv->to_dec($base_num);
        my $next;
        $next = $conv->to_base( $dec_num + $_ ) for 1..SEQ_LENGTH
    }
});

