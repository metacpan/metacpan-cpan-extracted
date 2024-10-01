##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package HasExports;

use base 'Exporter';

our @EXPORT = qw(
    &sub1
    sub2
    $scalar
    %hash
    @array
);

our @EXPORT_OK = (
    '&ok_sub1',
    'ok_sub2',
    '$ok_scalar',
    '%ok_hash',
    '@ok_array'
);

1;

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
