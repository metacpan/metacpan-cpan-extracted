use strict;
use warnings;
use utf8;

use Test::More;

BEGIN {
  use_ok 'TUI::Editors::Const', qw( sfSearchFailed );
  use_ok 'TUI::Editors::Util', qw(
    countLines
    iScan
    scan
  );
}

subtest 'countLines' => sub {
  is( countLines( '' ), 0, 'empty buffer' );
  is( countLines( 'plain text' ), 0, 'no line breaks' );
  is( countLines( "ab\r\ncd\nef" ), 2, 'counts line breaks' );
  is( countLines( "a\nb\nc\n", 4 ), 2, 'honors character limit' );
};

subtest 'scan' => sub {
  is( scan( 'abcdef', 6, 'abc' ), 0, 'match at beginning' );
  is( scan( 'abcdef', 6, 'cde' ), 2, 'match inside block' );
  is( scan( 'abcdef', 3, 'de' ), sfSearchFailed, 'honors block size' );
  is( scan( 'Abcdef', 6, 'abc' ), sfSearchFailed, 'case-sensitive' );
  is( scan( 'abcdef', 6, '' ), sfSearchFailed, 'empty search fails' );
};

subtest 'iScan' => sub {
  is( iScan( 'AbCdEf', 6, 'abc' ), 0, 'match at beginning' );
  is( iScan( 'AbCdEf', 6, 'CDE' ), 2, 'match inside block' );
  is( iScan( 'AbCdEf', 3, 'de' ), sfSearchFailed, 'honors block size' );
  is( 
    iScan( "Äpfel und Birnen", 16, "äpfel" ), 
    0,
    'uses Unicode case-insensitive matching'
  );
  is( iScan( 'a.b[c]', 6, '.B[' ), 1, 'search is literal' );
  is( iScan( 'abcdef', 6, '' ), sfSearchFailed, 'empty search fails' );
};

done_testing();
