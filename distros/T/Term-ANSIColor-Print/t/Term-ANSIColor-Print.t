# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Term-ANSIColor-Print.t'

#########################

use Test::More tests => 5;
BEGIN { use_ok('Term::ANSIColor::Print') }

#########################

my ( $str, @got, @expect );

my $p = Term::ANSIColor::Print->new(
    output => 'return',
    alias  => { happy => 'yellow_on_dark_red', },
);

$str = $p->green_on_white('x');

@got = map { ord $_ } split //, $str;

@expect = qw(
    27  91  57  50  109
    27  91  49  48  55  109
    120
    27  91  48  109
    10
);

is_deeply( \@got, \@expect, 'correct green on white markup' );

$str = $p->green_('x');

@got = map { ord $_ } split //, $str;

@expect = qw(
    27 91 57 50 109
    120
    27 91 48 109
);

is_deeply( \@got, \@expect, 'correct green with no eol' );

$str = $p->happy('x');

@got = map { ord $_ } split //, $str;

@expect = qw(
    27 91 57 51 109
    27 91 52 49 109
    120
    27 91 48 109
    10
);

is_deeply( \@got, \@expect, 'correct alias' );

$str = $p->happy();

@got = map { ord $_ } split //, $str;

@expect = qw( 10 );

is_deeply( \@got, \@expect, 'can print empty string' );

