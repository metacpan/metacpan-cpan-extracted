#!perl -w

BEGIN { unshift @INC, './lib'; }

use strict;
use warnings;
use Sub::Quotelike;

print "1..12\n";

my $test = 0;
sub ok ($$) {
    ++$test;
    my $message = ' - '.$_[1] if $_[1];
    if ($_[0]) {
	print "ok $test$message\n";
    } else {
	print "not ok $test$message\n";
    }
}

sub rot13 (") {
    local $_ = shift;
    tr/a-zA-Z/n-za-mN-ZA-M/;
    $_;
}

sub
	    foo
	    (')
	    {"bar"}

sub	qlc	('')	{ lc shift }
sub qqok(""); # Forward declaration of qqok()

ok( rot13(abc) eq 'nop', '(") without interpolation' );
my $foo = 'def'; # doesn't clash with foo//
ok( rot13/$foo/ eq q/qrs/, '(") with scalar interpolation' );
ok( rot13.abc..rot13.def. eq 'nopqrs', 'precedence' );
ok( foo$$ eq "bar", "(')" );
ok( &rot13(q(abc)) eq 'nop', 'bypass prototype' );
ok( qlc,AbCdEf, eq q,abcdef,, "('')" );
ok( qqok!Ensnry! eq 'Rafael', 'Forward declared function' );
my @qqok = ( foo => 'bar' ); # Fat comma quoting
ok( qqok'@qqok' eq "sbb one",
    '(") with array interpolation and fat comma preserved' );
my $qlc = \qlc;SHOUT;;
ok( $$qlc eq 'shout', 'Taking a reference' );
$foo = { foo => 'bar' };
ok( $foo->{foo}.$foo->{'foo'}.$foo->{ "foo" } eq foo// x 3,
    'bare hash key preserved' );

sub qqok ("") { &rot13(shift) }

no Sub::Quotelike;
ok( qq/foo/ eq "fo"."o", 'unimport' );
ok( &rot13(q(abc)) eq 'nop', 'bypass prototype, quotelike syntax disallowed' );
