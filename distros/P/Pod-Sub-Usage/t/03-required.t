#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

require Pod::Sub::Usage;
ok( Pod::Sub::Usage::sub2usage( 'sub2usage', 'Pod::Sub::Usage' ) );
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
