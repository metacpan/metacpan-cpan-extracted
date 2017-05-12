use strict;
use Test::More;
use Refine;
use Carp;

eval <<'TEST_CLASS' or die $@;
package Test::Class;
sub new { bless {}, shift }
$INC{'Test/Class.pm'} = 'generated';
TEST_CLASS

my $t = Test::Class->new;
$t->$_refine(throw => sub { Carp::confess('yikes!') });
eval { $t->throw };

if (Refine::SUB_NAME) {
  like $@, qr{\bTest::Class::WITH::throw::_0::throw\(}, 'throw() has a proper sub name';
}
else {
  like $@, qr{\bmain::__ANON__\(}, 'throw() has anon sub name';
}

done_testing;
