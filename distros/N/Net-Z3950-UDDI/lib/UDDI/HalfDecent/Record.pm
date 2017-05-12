package UDDI::HalfDecent::Record;
use strict;
use warnings;


=head1 NAME

UDDI::HalfDecent::Record - a business/service/etc. record from a UDDI registry

=head1 SYNOPSIS

 $business = new UDDI::HalfDecent::Record($rs, $node, 'business');
 $name = $business->xpath("name");

=head1 DESCRIPTION

Represents a business, service, or other object, as described by a
UDDI node and returned in response to a C<find_business()>,
C<find_service> or similar request.

=head1 METHODS

=head2 new()

 $record = new UDDI::HalfDecent::Record($rs, $node, $type);

Creates and returns a new UDDI object representing a business, service
or other.  Note that B<client code need never call this>: it is
invoked by the UDDI library itself, in methods such as
C<UDDI::HalfDecent::ResultSet::record()>.

This constructor takes three arguments: C<$rs> is the result-set
object for which it is created, and which will be used for logging,
etc; C<$node> is the context node of the element in the UDDI XML
response describing this object; and C<$type> is the type of object
described (C<business>, C<service>, etc.

=cut

sub new {
    my $class = shift();
    my($rs, $node, $type) = @_;

    my $this = bless {
	rs => $rs,
	node => $node,
	type => $type,
    }, $class;

    return $this;
}


=head2 xpath()

 $name = $record->xpath("name");
 $description = $record->xpath("uddi:description");

Returns the value corresponding to the specified XPath within the
business.  The specified XPaths may include the following predefined
namespace prefixes:

=over 4

=item xsd

C<http://www.w3.org/2001/XMLSchema>

=item xsi

C<http://www.w3.org/2001/XMLSchema-instance>

=item enc

C<http://schemas.xmlsoap.org/soap/encoding/>

=item env

C<http://schemas.xmlsoap.org/soap/envelope/>

=item uddi

The name space for whatever UDDI version is in effect.

=back

To simplify application code, the UDDI namespace is assumed if none is
specified.

=cut

sub xpath {
    my $this = shift();
    my($xpath) = @_;

    my $val = $this->{rs}->{xpc}->findvalue("$xpath", $this->{node});
    return $val if defined $val && $val ne "";
    return $val if $xpath =~ /^@/;
    $val = $this->{rs}->{xpc}->findvalue("uddi:$xpath", $this->{node});
    return $val;
}


=head2 as_xml()

 print $rec->as_xml();

Returns an XML representation of the whole record.

=cut

sub as_xml {
    my $this = shift();
    return $this->{node}->toString();
}


=head1 SEE ALSO

C<UDDI::HalfDecent>
is the module that uses this.  See also its SEE ALSOs.

=head1 AUTHOR, COPYRIGHT AND LICENSE

As for C<Net::Z3950::UDDI>.

=cut

1;
