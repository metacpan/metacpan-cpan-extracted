# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 4 };
use Script::Toolbox qw(:all);

#########################

$f = Open('> _XX_');
is( ref($f) , 'IO::File', 'Open write' );

$rc=print $f "1\n";
ok( $rc == 1, 'Open write' );

undef $f;

$f = Open('_XX_');
is( ref($f) , 'IO::File', 'Open read' );

@L=<$f>;
is( $L[0], "1\n", 'Open read' );


unlink ( '_XX_');
