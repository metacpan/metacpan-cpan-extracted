package Parse::AFP::MCF;
use base 'Parse::AFP::Record';

use constant SUBFORMAT => (
    'MCF::DataGroup'	=> ['n/a* XX', '*'],
);

1;
