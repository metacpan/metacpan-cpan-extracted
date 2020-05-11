#!/usr/bin/env perl

use strict;
use warnings;

# use Test::More;
use Test2::V0;

use Number::Textify ();

like dies {
  Number::Textify
      -> new;
},
  qr/Constructor expects at least one argument/,
  'dies with no params';


like dies {
  Number::Textify
      -> new( [],
            );
},
  qr/Ranges should be defined as array of arrays/,
  'dies with empty ranges array';


like dies {
  Number::Textify
      -> new( [ 'one',
              ],
            );
},
  qr/Ranges should be defined as array of arrays/,
  'dies with ranges array with not arrayrefs';


like dies {
  Number::Textify
      -> new( [ [],
              ],
            );
},
  qr/Ranges should be defined as array of arrays/,
  'dies with ranges array with empty arrayrefs';


like dies {
  Number::Textify
      -> new( [ [ 60, 'minute' ],
                [ 60, 'hour' ],
              ],
            );
},
  qr/Ranges should be defined in descending order/,
  'dies when ranges holds duplicate';

like dies {
  Number::Textify
      -> new( [ [ 60, 'minute' ],
                [ 60 * 60, 'hour' ],
              ],
            );
},
  qr/Ranges should be defined in descending order/,
  'dies when ranges not in descending order';

like dies {
  Number::Textify
      -> new( [ [ 60, 'minute' ],
                [ 60 * 60, 'hour' ],
              ],
              ':',
            );
},
  qr/Incorrect number of additional parameters/,
  'dies when odd number of additional parameters';

done_testing;

