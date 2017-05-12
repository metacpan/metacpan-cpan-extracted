
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::ExtraPorts' => {
    qw(state $ count $),
    '&as_xml' => q!qq(<extraports state="$self->{state}" ) .
                   qq(count="$self->{count}"/>);!

};

=pod

=head1 DESCRIPTION

This class holds information on ports found to be not
open on a host.

=head2 state()

State of the non-open ports: 'closed' or 'filtered.'

=head2 count()

Number of non-open ports found.

=cut

1;
