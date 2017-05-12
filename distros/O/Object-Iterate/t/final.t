use strict;

use Test::More;

use Object::Iterate qw(imap);

my $o = O->new();
my @o1 = imap { $_ } $o;
ok( eq_array( \@o1, [1..9] ), 
	'imap returns the right items on the first try' );
is( $o->{Array}, 'Done!', '__final__ did the right thing' );

BEGIN {
	package O;
	
	sub new { my $c = shift; 
		bless { Pos => 0, Array => [1..9], Pos => 0 }, $c }
	sub __more__  { $_[0]->{Pos} < @{ $_[0]->{Array} } }
	sub __next__  { $_[0]->{Array}[$_[0]->{Pos}++] }
	sub __final__ { $_[0]->{Array} = 'Done!' }
	}

done_testing();
