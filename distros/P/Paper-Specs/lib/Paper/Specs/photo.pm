
package Paper::Specs::photo;
use strict;
use base qw(Paper::Specs::base::brand);

=head1 Paper::Standard

Standard / well known paper formats

=cut

sub specs {

    return {
        name_short => "photo",
        name_long  => "Standard photo paper sizes",
    };

}

1;

