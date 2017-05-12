# $URL: //local/member/autrijus/Parse-AFP/lib/Parse/AFP/FNC.pm $ $Author: autrijus $
# $Rev: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Parse::AFP::FNC;
use base 'Parse::AFP::Record';

use constant SUBFORMAT => (
    Constant                    => 'a',
    PatternTechnologyIdentifier => 'H2',
    FNCReserved1                => 'a',
    UseFlags                    => 'C',
    UnitXBase                   => 'H2',
    UnitYBase                   => 'H2',
    UnitXValue                  => 'n',
    UnitYValue                  => 'n',
    MaxWidth                    => 'n',
    MaxHeight                   => 'n',
    FNORepeatingGroupLength     => 'C',
    FNIRepeatingGroupLength     => 'C',
    PatternDataAlignmentCode    => 'H2',
    PatternDataCount1           => 'a3',
    FNPRepeatingGroupLength     => 'C',
    FNMRepeatingGroupLength     => 'C',
#    ResolutionCode              => 'H2',
#    ResolutionXValue            => 'n',
#    ResolutionYValue            => 'n',
#    PatternDataCount2           => 'a3',
#    FNCReserved2                => 'a3',
#    FNNRepeatingGroupLength     => 'C',
#    FNNDataCount                => 'a3',
    # ...XXX
    Data => 'a*',    # not yet parsed!
);

1;
