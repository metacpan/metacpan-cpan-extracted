# $URL: //local/member/autrijus/Parse-AFP/lib/Parse/AFP/PTX/STO.pm $ $Author: autrijus $
# $Rev: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Parse::AFP::PTX::STO;
use base 'Parse::AFP::PTX::ControlSequence';

use constant SUBFORMAT => (
    Orientation     => 'H4',
    WrapDirection   => 'H4',
);

1;
