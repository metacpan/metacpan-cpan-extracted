
use strict;
use Class::Generate qw(class);

class 'Nmap::Scanner::ScanInfo' => {
    qw(type        $
       protocol    $
       numservices $
       services    $),
    '&as_xml' => q!
    
    return qq(<scaninfo type="$type" protocol="$protocol" ) .
           qq(numservices="$numservices" services="$services"/>\n);

    !
};

=pod

=head1 DESCRIPTION

This class represents Nmap Summary/scan information.

=head1 PROPERTIES

=head1 DESCRIPTION

This class represents Nmap Summary/scan information.

=head1 PROPERTIES

=head2 type()

=head2 protocol()

=head2 numservices()

=head2 services()

=cut

1;
