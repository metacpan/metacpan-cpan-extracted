
package TMTI::MyTypes;
use MooseX::Types::Implements qw( Implements );
use MooseX::Types -declare =>[qw(
    Breakable
    BreakableDriveable
)];

subtype Breakable,
    as Implements[qw(TMTI::Breakable)],
    message {
        "Object '$_' does not implement TMTI::Breakable"
    };

subtype BreakableDriveable,
    as Implements[qw( TMTI::Breakable TMTI::Driveable)],
    message {
        "Object '$_' does not implement both TMTI::Breakable and TMTI::Driveable"
    };

1;

