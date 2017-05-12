# $URL: //local/member/autrijus/Parse-AFP/lib/Parse/AFP/CFC.pm $ $Author: autrijus $
# $Rev: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Parse::AFP::CFC;
use base 'Parse::AFP::Record';

use constant SUBFORMAT => (
    CFIRepeatingGroupLength => 'C',
    Data                    => 'a*',
);

1;
