use strict;

use Test::More;

use Object::Iterate qw(imap);

my $o = O->new(1..9);
my @o1 = imap { $_ } $o;
ok( eq_array( \@o1, [2..9] ), 
	'imap returns the right items on the first try' );

# try again.  we need to reset the iterator, but the
# __init__ method should do that for us.
my @o2 = imap { $_ } $o;
ok( eq_array( \@o2, [2..9] ), 
	'imap returns the right items on the second try' );

BEGIN 
	{
	package O;
	
	sub new { my $c = shift; bless { Array => [@_], Pos => 0 }, $c }
	sub __init__ { $_[0]->{Pos} = 1 }
	sub __more__ { $_[0]->{Pos} < @{ $_[0]->{Array} } }
	sub __next__ { $_[0]->{Array}[$_[0]->{Pos}++] }
	}

done_testing();
