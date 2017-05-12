
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::OS::IPIdSequence' => {
    qw(class  $
       values $),
    '&as_xml' => q!qq(<ipidsequence class="$self->{class}" ) .
                   qq(values="$self->{values}"/>);!
};

1;

=pod

=head1 NAME 

IPIdSequence - IP identification sequence

=head2 class()

=head2 values()

=cut

__END__;
