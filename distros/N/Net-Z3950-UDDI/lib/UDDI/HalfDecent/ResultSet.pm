package UDDI::HalfDecent::ResultSet;
use strict;
use warnings;

use UDDI::HalfDecent::Record;

### At present, this class only represents sets of businesses.  When
#   we implement more methods, it will need generalising to represent
#   sets of other kinds of record.

=head1 NAME

UDDI::HalfDecent::ResultSet - a set of results from a UDDI query

=head1 SYNOPSIS

 $rs = $uddi->find_business(name => 'frog');
 $n = $rs->count();
 foreach $i (0 .. $n-1) {
     $bi = $rs->record($i);
 }

=head1 DESCRIPTION

This is a container class which allows access to the multiple records
found by various interrogation methods on a UDDI object.  Depending on
what method gave rise to the result-set it will contain different
kinds of objects, e.g. C<find_business()> will yield a result-set of
Business objects.  In a parallel universe, there are ResultSet
subclasses corresponding to each of the possible contained object
types, but that's not how we do things here.

=head1 METHODS

=head2 new()

 $uddi = new UDDI::HalfDecent::ResultSet($uddi, $xpc, $node, $class);

Creates and returns a new UDDI result-set object representing the
result of a search.  Note that B<client code need never call this>: it
is invoked by the UDDI library itself, in methods such as
C<find_business()>.

This constructor takes four arguments: C<$uddi> is the UDDI object
for which it is created, and which will be used for logging, etc;
C<$xpc> is an XPath content with all relevant namespaces registered;
and C<$node> is the context node of the list-containing element, which
in general will be different from the context-node registered as part
of the XPath context.  (If you didn't understand that last bit, don't
worry about it -- you won't be calling this constructor yourself,
remember?)  C<$class> is the class to which the individual result
records must belong.

=cut

# Actually, I don't think we need this.
#
#our %_class2xpath = (
#    business => "uddi:businessInfos/uddi:businessInfo"
#    service => "uddi:serviceInfos/uddi:serviceInfo"
#    binding => "uddi:bindingTemplate",
#    tmodel => "uddi:tModelInfos/uddi:tModelInfo"
#);

sub new {
    my $class = shift();
    my($uddi, $xpc, $node, $recclass) = @_;

    my $this = bless {
	uddi => $uddi,
	xpc => $xpc,
	node => $node,
	recclass => $recclass,
	count => undef,
	dom => [],		# The raw DOM nodes
	records => [],		# Corresponding wrapped objects
    }, $class;

    my $xpath;
    if ($recclass eq "binding") {
	$xpath = "uddi:bindingTemplate";
    } else {
	$xpath = "uddi:${recclass}Infos/uddi:${recclass}Info";
    }
    $this->{dom} = $xpc->findnodes($xpath, $node);
    $this->{count} = @{ $this->{dom} };

    return $this;
}


=head2 count()

 $n = $rs->count();

Returns the number of records in the result-set, e.g. the number of
businesses found by a C<find_business()> call.

=cut

sub count {
    my $this = shift();

    return $this->{count};
}


=head2 record()

 foreach $i (0 .. $n-1) {
     $bi = $rs->record($i);
 }

Returns a single record from the result-set, indexed from zero.

=cut

sub record {
    my $this = shift();
    my($index) = @_;

    my $count = $this->count();
    UDDI::HalfDecent::oops(error => "out of range",
			   detail => "record $index not in 0..$count")
	if $index < 0 || $index >= $count;

    my $rec = $this->{records}->[$index];
    if (!defined $rec) {
	my $dom = $this->{dom}->[$index];
	UDDI::HalfDecent::oops(error => "no DOM",
			       detail => "record $index in 0..$count")
	    if !defined $dom;

	$rec = $this->{records}->[$index] =
	    new UDDI::HalfDecent::Record($this, $dom);
    }

    return $rec;
}


=head1 SEE ALSO

C<UDDI::HalfDecent>
is the module that uses this.  See also its SEE ALSOs.

=head1 AUTHOR, COPYRIGHT AND LICENSE

As for C<Net::Z3950::UDDI>.

=cut

1;
