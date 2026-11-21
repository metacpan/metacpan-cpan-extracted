use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Help::Const',
    qw( MAXHELPTOPICID undefined wrapping notWrapping :cXXXX );
}

is( MAXHELPTOPICID, 16379 << 16, 'MAXHELPTOPICID is valid' );
is( undefined, 0, 'undefined is 0' );
is( wrapping, 1, 'wrapping is 1' );
is( notWrapping, 2, 'notWrapping is 2' );
is( cHelpViewer, "\x06\x07\x08", 'cHelpViewer palette bytes' );
is( cHelpWindow, "\x80\x81\x82\x83\x84\x85\x86\x87",
  'cHelpWindow palette bytes' );

done_testing();
