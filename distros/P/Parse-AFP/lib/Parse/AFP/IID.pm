# $URL: //local/member/autrijus/Parse-AFP/lib/Parse/AFP/IID.pm $ $Author: autrijus $
# $Rev: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Parse::AFP::IID;
use base 'Parse::AFP::Record';

use constant SUBFORMAT => (
    ConstantData1       => 'a12', # "0000 0960 0960 0000 0000 0000"
    XBase               => 'H2',
    YBase               => 'H2',
    XUnits              => 'n',
    YUnits              => 'n',
    XSize               => 'n',
    YSize               => 'n',
    ConstantData2       => 'a6', # "0000 0000 2D00"
    XCellSizeDefault    => 'n',
    YCellSizeDefault    => 'n',
    ConstantData3       => 'a',  # "0001"
    Color               => 'H4',
);

1;
