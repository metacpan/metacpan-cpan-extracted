package Nmap::Scanner::HostList;

use strict;

sub new {
    my $class = shift;
    my $me = { LISTREF => shift };

    my @keys = sort keys %{$me->{LISTREF}};
    $me->{KEYS} = \@keys;

    return bless $me, $class;
}

sub get_next {
    return $_[0]->{LISTREF}->{ shift @{$_[0]->{KEYS}} }
        if @{$_[0]->{KEYS}};
}

sub as_xml {

    my $self = shift;

    my $xml;

    while (my $host = $self->get_next()) {
        last unless defined $host;
        $xml .= $host->as_xml();
    }

    return $xml;

}

1;

=pod

=head2 DESCRIPTION

Holds a list of Nmap::Scanner::Host
objects.  get_next() returns a host
reference while there are hosts in
the list and returns undef when
the list is exhausted.  Hosts are 
indexed and sorted internally by primary  
IP address.

=head2 get_next()

Return the next Nmap::Scanner::Host from the list, or 
undef if the list is empty.

=head2 as_xml()

Returns an XML string representation of all hosts in the list. 

=cut
