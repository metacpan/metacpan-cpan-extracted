# $URL: //local/member/autrijus/Parse-AFP/lib/Parse/AFP/IOC.pm $ $Author: autrijus $
# $Rev: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Parse::AFP::IOC;
use base 'Parse::AFP::Record';

use constant SUBFORMAT => (
    Reserved1       => 'a',     # leading 00 of the next item
    XOffset         => 'n',
    Reserved2       => 'a',     # leading 00 of the next item
    YOffset         => 'n',
    XOrientation    => 'H4',
    YOrientation    => 'H4',
    ConstantData1   => 'a8',    # "0000 0000 0000 0000"
    XMap            => 'H4',
    YMap            => 'H4',
    ConstantData2   => 'a2',    # "FFFF"
);

1;
