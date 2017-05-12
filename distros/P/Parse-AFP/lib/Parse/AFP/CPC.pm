# $URL: //local/member/autrijus/Parse-AFP/lib/Parse/AFP/CPC.pm $ $Author: autrijus $
# $Rev: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Parse::AFP::CPC;
use base 'Parse::AFP::Record';

use constant SUBFORMAT => (
    GCGID                   => 'a8',
    UseFlags                => 'C',
    CPIRepeatingGroupLength => 'C',
    SpaceCharacterSection   => 'C',
    UseFlags2               => 'C',
#   Data => 'a*',    # not yet parsed!
);

1;
