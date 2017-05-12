
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::OS::Uptime' => {
    qw(seconds  $
       lastboot $),
    '&as_xml' => q!qq(<uptime seconds="$self->{seconds}" ) .
                   qq(lastboot="$self->{lastboot}"/>);!
};

1;

=pod

=head1 NAME

Uptime - uptime for remote host (not always available)

=head2 seconds()

Seconds up since last boot

=head2 lastboot()

Time/date of last boot

=cut
