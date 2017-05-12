#!perl

use Test::More tests => 4;

# don't import the filter
require_ok( 'Perl::Unsafe::Signals' );

my $o = Perl::Unsafe::Signals::get_unsafe_flag();

my $m = Perl::Unsafe::Signals::push_unsafe_flag();

is( $o, $m, 'got back old value' );

# PERL_SIGNALS_UNSAFE_FLAG's value is 0x0001
is( Perl::Unsafe::Signals::get_unsafe_flag() & 1, 1, 'signals flagged as unsafe' );

Perl::Unsafe::Signals::pop_unsafe_flag( $o );

is( Perl::Unsafe::Signals::get_unsafe_flag(), $o, "signal flag restored to $o" );
