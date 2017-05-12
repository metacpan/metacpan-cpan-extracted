#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

use Pod::Sub::Usage qw/sub2usage/;

ok( sub2usage( 'test', __PACKAGE__ ) );
is(
    Pod::Sub::Usage::pod_text( __FILE__, __PACKAGE__, 'test' ), '
This is the sub test

'
);



=head2 test

This is the sub test

=cut

sub test {}

1;

__END__