
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::OS::Fingerprint' => {
    qw(fingerprint  $),
    '&as_xml' => q!qq(<osfingerprint fingerprint="$self->{fingerprint}"/>)!
};

=pod

=head1 NAME

Fingerprint - Nmap fingerprint for OS

=head2 fingerprint()

    Nmap's fingerprint signature for this host

=cut

1;

__END__;
