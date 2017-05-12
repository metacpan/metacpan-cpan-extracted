use strict;
use warnings;

=head1 DESCRIPTION

X<$a=>1 X<$b=>2 and X<$c=>3

Don't forget X<$d=>"Four!"

=head1 ANOTHER SECTION

Now I'm talking about X<$e=>5!

=cut

use Test::More tests => 5;
use Pod::Constant qw(:all);

is( $a, 1 );
is( $b, 2 );
is( $c, 3 );
is( $d, 'Four!' );
is( $e, 5 );
