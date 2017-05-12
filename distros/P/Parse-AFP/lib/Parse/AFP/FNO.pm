# $URL: //local/member/autrijus/Parse-AFP/lib/Parse/AFP/FNO.pm $ $Author: autrijus $
# $Rev: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Parse::AFP::FNO;
use base 'Parse::AFP::Record';

use constant SUBFORMAT => (
    Reserved                => 'H4',	# '0000'
    CharacterRotation       => 'H4',    # 00/2D/5A/87 00
    MaxBaseOffset           => 'n',
    MaxCharacterIncrement   => 'n',
    SpaceCharacterIncrement => 'n',
    Data => 'a*',    # not yet parsed!
);

1;
