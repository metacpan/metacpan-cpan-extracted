
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::OS::TCPSequence' => {
    qw(index      $
       class      $
       difficulty $
       values     $),
    '&as_xml' => q!qq(<tcpsequence index="$self->{index}" ) .
                   qq(class="$self->{class}" ) .
                   qq(difficulty="$self->{difficulty}" ) .
                   qq(values="$self->{values}"/>);!
};

1;

=pod

=head1 NAME

TCPSequence - Information about TCP sequence mechanism of remote host

=head2 index()

=head2 class()

=head2 difficulty()

=head2 values()

=cut
