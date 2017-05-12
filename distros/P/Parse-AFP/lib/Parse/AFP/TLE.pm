package Parse::AFP::TLE;
use base 'Parse::AFP::Record';

1;
__END__

use constant SUBFORMAT => (
    'Triplet'   => [ 'C/a* X', '*' ],
    XUnitBase		=> 'C',
    YUnitBase		=> 'C',
    XLUnitsperUnitBase	=> 'n',
    YLUnitsperUnitBase	=> 'n',
    XPageSize		=> 'H6',
    YPageSize		=> 'H6',
    _			=> 'a*',
);

1;
