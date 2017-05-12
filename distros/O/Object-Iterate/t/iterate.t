use strict;

use Test::More;

use Object::Iterate qw(iterate);

my $o = T->new();
isa_ok( $o, 'T' );

my @out = ();
iterate { push @out, "$_$_" } $o;

my @expected = qw( AA BB CC DD EE FF );

ok( eq_array( \@out, \@expected ), 'Iterate returned the right thing' );

BEGIN {
	package T;
	
	sub new { bless { A => [ 'A' .. 'F' ] }, __PACKAGE__     }
	sub __init__ { $_[0]{Pos} = 0                   }
	sub __next__ { $_[0]{A}[ $_[0]{Pos}++ ]          }
	sub __more__ { $_[0]{Pos} > $#{ $_[0]{A} } ? 0 : 1 }
	}

done_testing();
