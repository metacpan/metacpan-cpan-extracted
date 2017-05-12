use strict;
use Class::Generate qw(class);

class 'Nmap::Scanner::Address' => {
    qw(addr     $
       addrtype $
       vendor   $),
    '&as_xml' => q!return qq(<address addr="$addr" ) .
                          qq(addrtype="$addrtype" ) .
                          qq(vendor="$vendor"/>);!
};

=pod

=head1 DESCRIPTION

This class represents an host address as represented by the scanning output from
nmap.

=head2 addr()

=head2 addrtype()

=head2 vendor()

=cut
