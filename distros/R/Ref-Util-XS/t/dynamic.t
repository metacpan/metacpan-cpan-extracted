use strict;
use warnings;
use Ref::Util::XS;
use Test::More tests => 2;

my $cb = Ref::Util::XS->can('is_arrayref');
ok( $cb->([]), 'is_arrayref with can()' );
ok( !$cb->({}), 'is_arrayref with can()' );
