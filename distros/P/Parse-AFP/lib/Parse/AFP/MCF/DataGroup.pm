package Parse::AFP::MCF::DataGroup;
use base 'Parse::AFP::Base';

use constant FORMAT => (
    Length	=> 'n',
    'Triplet'	=> [ 'C/a* X', '*' ],
);

1;
