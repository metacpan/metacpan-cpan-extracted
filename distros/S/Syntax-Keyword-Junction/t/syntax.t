use strict;
use warnings;

use Test::More;
use Test::Needs {
  'Sub::Exporter' => 0.986,
  'syntax'        => 0,
};

use syntax junction => {
  -all => { -prefix => 'syntax_' }
};

use Syntax::Keyword::Junction -all => { -prefix => 'orig_' };

ok orig_any(1,2,3) == 2, 'regular export works';
ok syntax_any(1,2,3) == 2, 'syntax export works';

done_testing;

