package OPCUA::Open62541::Client;

use strict;
use warnings;
require Exporter;
use parent 'Exporter';

use OPCUA::Open62541 qw(:ATTRIBUTEID :BROWSERESULTMASK :NODECLASS :NODEIDTYPE);

my %mapping_nodeclass_attributes;
# Base NodeClass
for (
    NODECLASS_OBJECT,
    NODECLASS_VARIABLE,
    NODECLASS_METHOD,
    NODECLASS_OBJECTTYPE,
    NODECLASS_VARIABLETYPE,
    NODECLASS_REFERENCETYPE,
    NODECLASS_DATATYPE,
    NODECLASS_VIEW
 ) {
    $mapping_nodeclass_attributes{$_}{ATTRIBUTEID_NODEID()} = 'm';
    $mapping_nodeclass_attributes{$_}{ATTRIBUTEID_NODECLASS()} = 'm';
    $mapping_nodeclass_attributes{$_}{ATTRIBUTEID_BROWSENAME()} = 'm';
    $mapping_nodeclass_attributes{$_}{ATTRIBUTEID_DISPLAYNAME()} = 'm';
    $mapping_nodeclass_attributes{$_}{ATTRIBUTEID_DESCRIPTION()} = 'o';
    $mapping_nodeclass_attributes{$_}{ATTRIBUTEID_WRITEMASK()} = 'o';
    $mapping_nodeclass_attributes{$_}{ATTRIBUTEID_USERWRITEMASK()} = 'o';
    $mapping_nodeclass_attributes{$_}{ATTRIBUTEID_ROLEPERMISSIONS()} = 'o';
    $mapping_nodeclass_attributes{$_}{ATTRIBUTEID_USERROLEPERMISSIONS()} = 'o';
    $mapping_nodeclass_attributes{$_}{ATTRIBUTEID_ACCESSRESTRICTIONS()} = 'o';
}

# ReferenceType NodeClass
$mapping_nodeclass_attributes{NODECLASS_REFERENCETYPE()}{ATTRIBUTEID_ISABSTRACT()} = 'm';
$mapping_nodeclass_attributes{NODECLASS_REFERENCETYPE()}{ATTRIBUTEID_SYMMETRIC()} = 'm';
$mapping_nodeclass_attributes{NODECLASS_REFERENCETYPE()}{ATTRIBUTEID_INVERSENAME()} = 'o';

# View NodeClass
$mapping_nodeclass_attributes{NODECLASS_VIEW()}{ATTRIBUTEID_CONTAINSNOLOOPS()} = 'm';
$mapping_nodeclass_attributes{NODECLASS_VIEW()}{ATTRIBUTEID_EVENTNOTIFIER()} = 'm';

# Object NodeClass
$mapping_nodeclass_attributes{NODECLASS_OBJECT()}{ATTRIBUTEID_EVENTNOTIFIER()} = 'm';

# Variable NodeClass
$mapping_nodeclass_attributes{NODECLASS_VARIABLE()}{ATTRIBUTEID_VALUE()} = 'm';
$mapping_nodeclass_attributes{NODECLASS_VARIABLE()}{ATTRIBUTEID_DATATYPE()} = 'm';
$mapping_nodeclass_attributes{NODECLASS_VARIABLE()}{ATTRIBUTEID_VALUERANK()} = 'm';
$mapping_nodeclass_attributes{NODECLASS_VARIABLE()}{ATTRIBUTEID_ARRAYDIMENSIONS()} = 'o';
$mapping_nodeclass_attributes{NODECLASS_VARIABLE()}{ATTRIBUTEID_ACCESSLEVEL()} = 'm';
$mapping_nodeclass_attributes{NODECLASS_VARIABLE()}{ATTRIBUTEID_USERACCESSLEVEL()} = 'm';
$mapping_nodeclass_attributes{NODECLASS_VARIABLE()}{ATTRIBUTEID_MINIMUMSAMPLINGINTERVAL()} = 'o';
$mapping_nodeclass_attributes{NODECLASS_VARIABLE()}{ATTRIBUTEID_HISTORIZING()} = 'm';
$mapping_nodeclass_attributes{NODECLASS_VARIABLE()}{ATTRIBUTEID_ACCESSLEVELEX()} = 'o';

# Method NodeClass
$mapping_nodeclass_attributes{NODECLASS_METHOD()}{ATTRIBUTEID_EXECUTABLE()} = 'm';
$mapping_nodeclass_attributes{NODECLASS_METHOD()}{ATTRIBUTEID_USEREXECUTABLE()} = 'm';

# export mapping between nodeclass and valid attribute IDs
sub get_mapping_nodeclass_attributeid { %mapping_nodeclass_attributes };

our @EXPORT_OK = qw(get_mapping_nodeclass_attributeid);

my %attributeid_ids = OPCUA::Open62541::get_mapping_attributeid_ids;

# read namespace array and return list of names
sub get_namespaces {
    my $self = shift;

    my ($value) = $self->get_attributes({
	NodeId_namespaceIndex => 0,
	NodeId_identifierType => NODEIDTYPE_NUMERIC,
	NodeId_identifier     => OPCUA::Open62541::NS0ID_SERVER_NAMESPACEARRAY,
    }, 'value');

    return @{$value->{DataValue_value}{Variant_array} // []};
}

# read attributes for node ID
# allows ATTRIBUTE IDs and names
sub get_attributes {
    my ($self, $nodeid, @attributes) = @_;

    # is there any default that
    die 'no attributes for get_attributes'
	if not @attributes;

    # convert attribute names to IDs
    @attributes = map { $attributeid_ids{$_} // $_ } @attributes;

    my $response = $self->Service_read({
	ReadRequest_nodesToRead => [
	    map {
		{ReadValueId_nodeId => $nodeid, ReadValueId_attributeId => $_}
	    } @attributes
	],
    });

    my $status = $response->{"ReadResponse_responseHeader"}{ResponseHeader_serviceResult};
    die "Read failed with $status"
	if $status ne 'Good';

    return @{$response->{ReadResponse_results} // []};
}

# read references for node ID
# controll browse request via %args
# automaticalle makes browseNext request for continuation points
sub get_references {
    my ($self, $nodeid, %args) = @_;

    my $result_mask       = $args{result_mask} // BROWSERESULTMASK_NONE;
    my $include_subtypes  = $args{include_subtypes} // 1;
    my $browse_direction  = $args{browse_direction} // 2;
    my $reference_type_id = $args{reference_type_id} // {
	NodeId_namespaceIndex => 0,
	NodeId_identifierType => NODEIDTYPE_NUMERIC,
	NodeId_identifier => OPCUA::Open62541::NS0ID_REFERENCES,
    };

    my $request = {
	BrowseRequest_requestedMaxReferencesPerNode => 0,
	BrowseRequest_nodesToBrowse => [{
	    BrowseDescription_nodeId => $nodeid,
	    BrowseDescription_browseDirection => $browse_direction,
	    BrowseDescription_referenceTypeId => $reference_type_id,
	    BrowseDescription_includeSubtypes => $include_subtypes,
	    BrowseDescription_resultMask => $result_mask,
	}],
    };

    my $type = 'Browse';
    my @references;
  NEXT:
    my $response = $type eq 'Browse' ? $self->Service_browse($request)
	: $self->Service_browseNext($request);

    my $status = $response->{"${type}Response_responseHeader"}{ResponseHeader_serviceResult};
    die "$type failed with $status"
	if $status ne 'Good';

    my $result = $response->{"${type}Response_results"}[0];
    push @references,
	@{$result->{BrowseResult_references} // []};

    if (my $continuation_point = $result->{"BrowseResult_continuationPoint"}) {
	# continue with browseNext requests if we found continuation points
	$type = 'BrowseNext';
	$request = {
	    BrowseNextRequest_continuationPoints => [$continuation_point]
	};
	goto NEXT;
    }

    return @references
}

1;

__END__

=pod

=head1 NAME

OPCUA::Open62541::Client - High level functions for open62541 OPC UA client

=head1 SYNOPSIS

  my @namespaces = $client->get_namespaces()

  my @attributes = $client->get_attributes($nodeid, @attributes);

  my @references = $client->getReferences($nodeid);

=head1 DESCRIPTION

This is the documentation for high level client functionality.
For the fucntions directly wrapped around open62541 see L<OPCUA::Open62541>.

=head2 METHODS

These methods require a I<OPCUA::Open62541::Client> and will fail if the client
is not already connected to an OPC UA server.

By default these methods will check the service results of responses and will
DIE if the status code is not I<Good>.

=over 4

=item @namespaces = $client->get_namespaces()

Reads the I<SERVER_NAMESPACEARRAY> node from namespace 0 and returns the
namespace names as a list.

=item @attributes = $client->get_attributes($nodeid, @attributeids)

Makes a read requests for the specified node ID and attributes.
Attributes can be either ATTRIBUTEID constants or the short names (see
L<OPCUA::Open62541::Constant/get_mapping_attributeid_names>.

Returns the results as I<DataValue>s.

=item @references = $client->get_references($nodeid, %request_args)

Makes a browse request for the specified node ID.
If the server returns continuation points, this method will use browseNext
requests until no more continuation points are returned.

The I<%request_args> correspond to the BrowseDescription parameters and allows
to set the following keys in the browse request:

=over 4

=item browse_direction

Default is 2 (I<BOTH>).

=item include_subtypes

Default is I<1>.

=item reference_type_id

Default is the I<REFERENCES> node from namespace 0.

=item result_mask

Default is I<BROWSERESULTMASK_NONE>.

=back

Returns all results as I<ReferenceDescription>s.

=back

=head2 UTILITY FUNCTIONS

These functions are for convenience and do not require a
I<OPCUA::Open62541::Client> object.

=over 4

=item %hash = get_mapping_nodeclass_attributeid()

Returns a hash which maps nodeclasses to their available attribute IDs.
The value indicates if the attribute is mandatory (I<m>) or optional (I<o>).

=back

=head1 SEE ALSO

OPC UA library, L<https://open62541.org/>

OPC Foundation, L<https://opcfoundation.org/>

OPCUA::Open62541

=head1 AUTHORS

Alexander Bluhm E<lt>bluhm@genua.deE<gt>,
Anton Borowka,

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 Alexander Bluhm

Copyright (c) 2025 Anton Borowka

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Thanks to genua GmbH, https://www.genua.de/ for sponsoring this work.

=cut
