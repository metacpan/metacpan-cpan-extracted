use v5.22;
use warnings;

use Test::More;

use Multi::Dispatch;

multi anon ($)             { return 1 }
multi anon ($, $)          { return 2 }
multi anon ($, $, @)       { return 'many' }
multi anon ($, $, $, $, %) { return 'many even' }

is anon(1),    1           => 'One anonymous parameter';
is anon(1,2),  2           => 'Two anonymous parameters';
is anon(1..3), 'many'      => 'Many anonymous parameters';
is anon(1..6), 'many even' => 'Many even anonymous parameters';


multi opt_anon ($ =     ) { return 0 }
multi opt_anon ($, $ = 1) { return 1 }

is opt_anon( ),   0 => "Anonymous optional parameter (absent)";
is opt_anon(1),   1 => "Anonymous optional parameter (present)";
is opt_anon(1,2), 1 => "Anonymous two optional parameters";


done_testing();
