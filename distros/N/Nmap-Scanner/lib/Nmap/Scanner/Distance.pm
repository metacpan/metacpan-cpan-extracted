
use strict;
use Class::Generate qw(class);

class 'Nmap::Scanner::Distance' => {
    qw(value       $),
    '&as_xml' => q!
    
    return qq(<distance value="$value"/>);

    !
};

=pod

=head1 DESCRIPTION

This class represents the hop distance nmap estimates this host is from
the host running the scan.

=head1 PROPERTIES

=head2 value()

=cut

1;
