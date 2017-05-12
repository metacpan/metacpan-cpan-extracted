# $URL: //local/member/autrijus/Parse-AFP/lib/Parse/AFP/ICP.pm $ $Author: autrijus $
# $Rev: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Parse::AFP::ICP;
use base 'Parse::AFP::Record';

use constant SUBFORMAT => (
    XCellOffset     => 'n',
    YCellOffset     => 'n',
    XCellSize       => 'n',
    YCellSize       => 'n',
    XFillSize       => 'n',
    YFillSize       => 'n',
);

1;
