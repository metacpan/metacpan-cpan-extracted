package Parse::AFP::MCF1;
use base 'Parse::AFP::Record';

use constant SUBFORMAT => (
    RepeatingGroupLength    => 'C',
    _			    => 'a3',
    'MCF1::DataGroup'	    => ['a{$RepeatingGroupLength}', '*'],
);

1;
