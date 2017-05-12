
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::OS::TCPTSSequence' => {
    qw(class  $
       values $),
    '&as_xml' => q!qq(<tcptssequence class="$self->{class}" ) .
                   ($self->{'values'} ? qq(values="$self->{values}") : '') .
                   '/>';!
};

1;

=pod

=head1 NAME

TCPTSSequence - TCP time stamp sequence of remote host

=head2 class()

=head2 values()

=cut
