
package Paper::Specs::Avery;
use strict;
use base qw(Paper::Specs::base::brand);

=head1 Paper::Avery

Information about labels and card forms that Avery Dennison

=cut

sub specs {

    return {
        name_short => 'Avery',
        name_long  => 'Avery-Dennison',
    };

}

1;

