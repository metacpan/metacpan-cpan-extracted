=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * '*.h'

=back

=cut

use strict ;
use warnings ;
use Data::Dumper ;

use PBS::Output ;
#-------------------------------------------------------------------------------

PBS::Rules::AddRule 'lib_dep', ['*/*.h' => '*.z'] ;

