use strict;
use Class::Generate qw(class);

class 'Nmap::Scanner::Hostname' => {
    qw( name $ type $ ),
    '&as_xml' => q(qq!<hostname name="$name" type="$type"/>!;)
};

=pod

=head1 Name

Hostname - Holds a host's DNS name and the type of DNS record used
           to get the name (CNAME or PTR).

=head2 name()

Name of host

=head2 type()

Type of name record (PTR, CNAME)

=cut

1;
