# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Regexp-Parser.t'

use strict;
use warnings;

use Test::More tests => 7;
use Regexp::Parser;

my $r = Regexp::Parser->new;
my $rx = '^(a(bc)+(d?))((f)+)$';
ok( $r->regex($rx), 'parse regex' );

for (@{ $r->captures }) {
  chomp(my $exp = <DATA>);
  is( join("\t", $_->nparen, $_->visual), $exp, "capture: $exp" );
}

is( scalar(<DATA>), "DONE\n", 'all captures checked' );

__DATA__
1	(a(bc)+(d?))
2	(bc)
3	(d?)
4	((f)+)
5	(f)
DONE
