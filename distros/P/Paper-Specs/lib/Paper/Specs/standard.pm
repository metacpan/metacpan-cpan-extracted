
package Paper::Specs::standard;
use strict;
use base qw(Paper::Specs::base::brand);

=head1 Paper::Standard

Standard / well known paper formats

=cut

sub specs {

    return {
        name_short => 'standard',
        name_long  => 'Standard paper sizes',
    };

}

1;

