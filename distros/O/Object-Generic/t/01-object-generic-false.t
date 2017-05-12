
use Test::More tests => 20 ;

use strict;
use warnings;
use Object::Generic::False qw(false);

# diag("testing Object::Generic::False");

ok( defined false, q(defined false) );
ok( (not false), q(not false ) );
ok( (not Object::Generic::False->new), q(not Object::Generic::False->new ) );
ok( false eq Object::Generic::False->new, q(false eq Object::Generic::False->new ) );
ok( false == Object::Generic::False->new, q(false == Object::Generic::False->new ) );
ok( 0==false, q(0==false ) );
ok( false==0, q(false==0 ) );
ok( '' eq false, q('' eq false ) );
ok( false eq '', q(false eq '' ) );
ok( not (2+false), q(not (2+false) ) );
ok( not (false+2), q(not (false+2) ) );
ok( not (2-false()), q(not (2-false()) ) );
ok( not (false-2), q(not (false-2) ) );
ok( not (2*false), q(not (2*false) ) );
ok( not (false*2), q(not (false*2) ) );
ok( not (false()/2), q(not (false()/2) ) );
ok( not (2/false()), q(not (2/false()) ) );
ok( "hi" eq "hi".false, q("hi" eq "hi".false ) );
ok( (not false->foo), q(not false->foo ) );
ok( (not false->foo->bar), q(not false->foo->bar ) );

