
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::OS::PortUsed' => {
    qw(state  $
       proto  $
       portid $),
    '&as_xml' => q!qq(<portused state="$self->{state}" ) .
                   qq(proto="$self->{proto}" portid="$self->{portid}"/>);!
};

=pod

=head1 NAME

PortUsed - Port used for OS identification

=head2 state()

=head2 proto()

=head2 portid()

=cut

1;

__END__;
