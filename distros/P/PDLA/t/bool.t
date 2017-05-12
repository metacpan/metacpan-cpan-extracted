use Test::More tests => 5;
use Test::Exception;
use PDLA::LiteF;
use strict;
use warnings;

#  PDLA::Core::set_debugging(1);
kill 'INT',$$  if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

{
	my $pa = zeroes 1,1,1;
	ok !$pa;
}

{
	my $pa = ones 3;
	throws_ok { print "oops\n" if $pa } qr/multielement/;
	ok all $pa;
}

{
	my $pa = pdl byte, [ 0, 0, 1 ];
	ok any $pa > 0;
}

{
	my $pa = ones 3;
	my $pb = $pa + 1e-4;
	ok all PDLA::approx $pa, $pb, 1e-3;
}
