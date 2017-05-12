# t/06_no_scores.t - four basic tests for 'no underscores' option
use Test::More 
tests => 41;
# qw(no_plan);
use strict;
use warnings;

BEGIN { use_ok( 'String::PerlIdentifier' ); }

our @lower =  qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
our @upper = map { uc($_) } @lower;
our @eligibles = (@upper, @lower);
our @chars = (@eligibles, 0..9);

our %eligibles = map {$_,1} @eligibles;
our %chars = map {$_,1} @chars;

four_basic_tests() for (1..10);

sub four_basic_tests {
    my $varname = make_varname( {
        underscores => 0,
    } );
    my $length = length($varname);
    ok( ($length >= 3), "length meets or exceeds minimum");
    ok( ($length <= 20), "length meets or is less than maximum");
    
    _first_and_subsequent_no_scores($varname);
}

sub _first_and_subsequent_no_scores {
    my $varname = shift;
    my @els = split(q{}, $varname);
    ok( $eligibles{$els[0]},
        "first character in variable is letter, but not an underscore");
    my @balance = @els[1..$#els];
    my $factor = 0;
    while ( defined ( my $k = shift @balance ) ) {
        $factor = 1 if ! $chars{$k};
        last if $factor;
    }
    ok(! $factor, "characters 2..last are letters or numerals; no underscores");
}

