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
      -> new( undef,
            );
},
  qr/Ranges should be defined as array of arrays/,
  'dies with undef insted of ranges array';


like dies {
  Number::Textify
      -> new( 'scalar',
            );
},
  qr/Ranges should be defined as array of arrays/,
  'dies with non arrayref insted of ranges array';


like dies {
  Number::Textify
      -> new( [],
            );
},
  qr/Ranges should be defined as array of arrays/,
  'dies with empty ranges array';


like dies {
  Number::Textify
      -> new( [ undef,
              ],
            );
},
  qr/Ranges should be defined as array of arrays/,
  'dies with ranges array with not arrayrefs, but undef';


like dies {
  Number::Textify
      -> new( [ 'one',
              ],
            );
},
  qr/Ranges should be defined as array of arrays/,
  'dies with ranges array with not arrayrefs, but scalar';


like dies {
  Number::Textify
      -> new( [ { one => 1,
                },
              ],
            );
},
  qr/Ranges should be defined as array of arrays/,
  'dies with ranges array with not arrayrefs, but hashref';


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
      -> new( [ [ -2 ],
              ],
            );
},
  qr/Ranges should be defined as array of arrays/,
  'dies with ranges array with arrayref with negative value';


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
      -> new( [ [ 60 * 60, 'hour' ],
                [ 60, 'minute' ],
              ],
              ':',
            );
},
  qr/Incorrect number of additional parameters/,
  'dies when odd number of additional parameters';

{
  my $converter = Number::Textify
    -> new( [ [ 10 ],
              [ 0 ],
            ],
          );

  like dies {
    $converter
      -> new( [ [ 20 ],
                [ 0 ],
              ],
            );
  },
    qr/I'm only a class method!/,
    'dies when called on object';
}

# and one for object method on class
like dies {
  Number::Textify
      -> textify( 20 );
},
  qr/I'm only an object method!/,
  'object method dies on class';

done_testing;

