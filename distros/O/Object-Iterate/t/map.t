use Test::More;

use Object::Iterate qw(imap);
use Object::Iterate::Tester;

my $o = Object::Iterate::Tester->new();
isa_ok( $o, 'Object::Iterate::Tester' );

my @O = imap { uc } $o;

my @expected = qw( A B C D E F );

ok( eq_array( \@O, \@expected ), 'imap outputs right results' );

done_testing();
