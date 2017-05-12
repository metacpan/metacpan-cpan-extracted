#!perl

use Test::More tests => 2;

use Perl::Unsafe::Signals;

my $o = Perl::Unsafe::Signals::get_unsafe_flag();

UNSAFE_SIGNALS {
    # PERL_SIGNALS_UNSAFE_FLAG's value is 0x0001
    is( Perl::Unsafe::Signals::get_unsafe_flag() & 1, 1, 'signals flagged as unsafe' );
};

is( Perl::Unsafe::Signals::get_unsafe_flag(), $o, "signal flag restored to $o" );
