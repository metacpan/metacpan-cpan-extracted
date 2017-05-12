package Parse::AFP::PGD;
use base 'Parse::AFP::Record';

use constant SUBFORMAT => (
    XUnitBase		=> 'C',
    YUnitBase		=> 'C',
    XLUnitsperUnitBase	=> 'n',
    YLUnitsperUnitBase	=> 'n',
    Reserved1		=> 'C', # '00'
    XPageSize		=> 'n',
    Reserved2		=> 'C', # '00'
    YPageSize		=> 'n',
    _			=> 'a*',
);

1;
