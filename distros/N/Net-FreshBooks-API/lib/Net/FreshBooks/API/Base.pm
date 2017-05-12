use strict;
use warnings;

package Net::FreshBooks::API::Base;
$Net::FreshBooks::API::Base::VERSION = '0.24';
use Moose;

with 'Net::FreshBooks::API::Role::Common';

use Carp qw( carp croak );
use Clone qw(clone);
use Data::Dump qw( dump );
use Scalar::Util qw( blessed reftype );
use XML::LibXML qw( XML_ELEMENT_NODE );
use XML::Simple;
use LWP::UserAgent;

use Net::FreshBooks::API::Iterator;

my %plural_to_singular = (
    clients  => 'client',
    contacts => 'contact',
    invoices => 'invoice',
    lines    => 'line',
    payments => 'payment',
    nesteds  => 'nested',    # for testing
);

has '_fb' => ( is => 'rw', required => 0 );
has '_sent_xml' => ( is => 'rw' );

sub new_from_node {
    my $class = shift;
    my $node  = shift;

    my $self = bless {}, $class;
    $self->_fill_in_from_node( $node );
    return $self;
}

sub copy {
    my $self  = shift;
    my $class = ref $self;
    return $class->new( _fb => $self->_fb );
}

# this method is called recursively as it works its way through the XML
# elements

sub _fill_in_from_node {
    my $self    = shift;
    my $in_node = shift;    # XML::LibXML::Element

    # parse it as a new node so that the matching is more reliable
    my $parser = XML::LibXML->new();
    my $node   = $parser->parse_string( $in_node->toString );

    # clean up all the keys
    delete $self->{$_} for grep { !m/^_/x } keys %$self;

    my $fields_config = $self->_fields;

    # copy across the new values provided
    foreach my $key ( grep { !m/^_/x } keys %$fields_config ) {

        my $xpath .= sprintf "//%s/%s", $self->node_name, $key;

        # check that this field is not a special one
        if ( my $class = $fields_config->{$key}{made_of} ) {

            my ( $match ) = $node->findnodes( $xpath );

            # avoid this error: Can't call method "childNodes" on an undefined
            # value at Net/FreshBooks/API/Base.pm
            # line 174
            next if !$match;
            if ( $fields_config->{$key}{presented_as} eq 'array' ) {

                my @new_objects = map { $class->new_from_node( $_ ) }
                    grep { $_->nodeType eq XML_ELEMENT_NODE }
                    $match->childNodes();
                $self->{$key} = \@new_objects;
            }

            elsif ( $fields_config->{$key}{presented_as} eq 'object' ) {

                my $inflated = $class->new;
                my $f        = $inflated->_fields;

                # convert XML to HASHREF as it's easier to work with
                my $node_as_ref = XMLin( $match->toString );

                foreach my $field ( keys %{$f} ) {

                    if ( exists $f->{$field}->{made_of} ) {
                        my $new_class = $f->{$field}->{made_of};
                        my $obj       = $new_class->new_from_node( $match );
                        $inflated->$field( $obj );
                    }
                    else {
                        $inflated->$field( $node_as_ref->{$field} );
                    }
                }
                $self->{$key} = $inflated;
            }
            else {
                $self->{$key}                            #
                    = $match                             #
                    ? $class->new_from_node( $match )    #
                    : undef;
            }

        }
        else {
            my $val = $node->findvalue( $xpath );
            $self->{$key} = $val;
        }
    }

    return $self;

}

sub send_request {
    my $self = shift;
    my $args = shift;

    my $method = $args->{_method};

    my %frequency_fix = %{ $self->_frequency_cleanup };

    my $pattern = join "|", keys %frequency_fix;

    $self->_log( debug => "Sending request for $method" );

    my $request_xml = $self->parameters_to_request_xml( $args );
    $request_xml
        =~ s{<frequency>($pattern)</frequency>}{<frequency>$frequency_fix{$1}</frequency>}gxms;

    $self->_log( debug => $request_xml );
    $self->_request_xml( $request_xml );

    my $return_xml = $self->send_xml_to_freshbooks( $request_xml );

    $self->_log( debug => $return_xml );
    $self->_return_xml( $return_xml );

    my $response_node = $self->response_xml_to_node( $return_xml );

    $self->_log( debug => "Received response for $method" );

    return $response_node;
}

sub method_string {
    my $self   = shift;
    my $action = shift;

    return $self->api_name . '.' . $action;
}

sub api_name {
    my $self = shift;
    my $name = ref( $self ) || $self;
    $name =~ s{^.*::}{}x;
    return lc $name;
}

sub node_name {
    my $self = shift;
    return $self->api_name;
}

sub id_field {
    my $self = shift;
    return $self->api_name . "_id";
}

sub field_names {
    my $self  = shift;
    my @names = sort keys %{ $self->_fields };
    return @names;
}

sub field_names_rw {
    my $self   = shift;
    my $fields = $self->_fields;

    my @names = sort
        grep { $fields->{$_}{is} eq 'rw' }
        keys %$fields;

    return @names;
}

sub parameters_to_request_xml {
    my $self       = shift;
    my $params     = shift;
    my $parameters = clone( $params );

    my $dom = XML::LibXML::Document->new( '1.0', 'utf-8' );

    my $root = XML::LibXML::Element->new( 'request' );
    $dom->setDocumentElement( $root );

    $self->construct_element( $root, $parameters );

    return $dom->toString( 1 );
}

sub construct_element {
    my $self    = shift;
    my $element = shift;
    my $hashref = shift;

    foreach my $key ( sort keys %$hashref ) {
        my $val = $hashref->{$key};

        # avoid "Unknown currency" API error
        next if $key eq 'currency_code' && !$val;

        # line_id is returned, but not sent
        next if $key eq 'line_id';

        # keys starting with an underscore are attributes
        if ( my ( $attr_key ) = $key =~ m{ \A _ (.*) \z }x ) {
            $element->setAttribute( $attr_key, $val );
        }

        # scalar values are text nodes
        elsif ( ref $val eq '' ) {
            $element->appendTextChild( $key, $val || '' );
        }

        # arrayrefs are groups of nested values
        elsif ( ref $val eq 'ARRAY' ) {

            my $singular_key = $plural_to_singular{$key}
                || croak "could not convert '$key' to singular";

            my $wrapper = XML::LibXML::Element->new( $key );
            $element->addChild( $wrapper );

            foreach my $entry_val ( @$val ) {
                my $entry_node = XML::LibXML::Element->new( $singular_key );
                $wrapper->addChild( $entry_node );

                # LineItems were including methods from Role/Common
                my $class = blessed $entry_val;

                if ( $class ) {
                    my $new_entry = {};
                    my $fields    = $class->_fields;

                    foreach my $key ( keys %{$fields} ) {
                        $new_entry->{$key} = $entry_val->$key
                            if $entry_val->$key;
                    }

                    $entry_val = $new_entry;
                }

                $self->construct_element( $entry_node, $entry_val );
            }
        }
        elsif ( ref $val eq 'HASH' || ( $val && blessed $val ) ) {
            my $wrapper = XML::LibXML::Element->new( $key );
            $element->addChild( $wrapper );
            $self->construct_element( $wrapper, $val );

        }

    }

    return;
}

sub response_xml_to_node {
    my $self = shift;
    my $xml = shift || croak "No XML passed in";

    # get rid of any namespaces that will prevent simple xpath expressions
    $xml =~ s{ \s+ xmlns=\S+ }{}xg;

    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_string( $xml );

    my $response        = $dom->documentElement();
    my $response_status = $response->getAttribute( 'status' );

    if ( $response_status ne 'ok' ) {
        my $msg = XMLin( $xml );
        warn $self->_sent_xml if $self->verbose;
        my $error = "FreshBooks server returned error: '$msg->{error}'";
        $self->_handle_server_error( $error );
    }
    else {
        $self->last_server_error( undef );
    }

    return $response;
}

sub send_xml_to_freshbooks {

    my $self        = shift;
    my $xml_to_send = shift;

    my $fb       = $self->_fb;
    my $response = undef;
    $self->_sent_xml( $xml_to_send );

    if ( $fb->auth_token ) {

        $self->_log( debug => "Not using OAuth" );

        my $ua      = $fb->ua;
        my $request = HTTP::Request->new(
            'POST',              # method
            $fb->service_url,    # url
            undef,               # header
            $xml_to_send         # content
        );
        $response = $ua->request( $request );

    }
    else {

        $self->_log( debug => "using OAuth" );

        $response = $fb->oauth->restricted_request( $fb->service_url,
            $xml_to_send );

    }

    if ( !$response->is_success ) {
        croak "FreshBooks request failed: " . $response->status_line;
        $self->_handle_server_error(
            "FreshBooks request failed: " . $response->status_line );
    }

    return $response->content;
}

# When FreshBooks returns info on recurring items, it does not return the same
# frequency values as the values it requests.  This method provides a lookup
# table to fix this issue.

sub _frequency_cleanup {

    my $self = shift;

    return {
        'y'  => 'yearly',
        'w'  => 'weekly',
        '2w' => '2 weeks',
        '4w' => '4 weeks',
        'm'  => 'monthly',
        '2m' => '2 months',
        '3m' => '3 months',
        '6m' => '6 months',
    };

}

__PACKAGE__->meta->make_immutable( inline_constructor => 1 );

1;

# ABSTRACT: Base class

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Base - Base class

=head1 VERSION

version 0.24

=head2 new_from_node

  my $new_object = $class->new_from_node( $node );

Create a new object from the node given.

=head2 copy

  my $new_object = $self->copy(  );

Returns a new object with the fb object set on it.

=head2 create

  my $new_object = $self->create( \%args );

Create a new object. Takes the arguments and uses them to create a new entry
at the FreshBooks end. Once the object has been created a 'get' request is
issued to fetch the data back from FreshBooks and to populate the object.

=head2 update

  my $object = $object->update();

Update the object, saving any changes that have been made since the get.

=head2 get

  my $object = $self->get( \%args );

Fetches the object using the FreshBooks API.

=head2 list

  my $iterator = $self->list( $args );

Returns an iterator that represents the list fetched from the server.
See L<Net::FreshBooks::API::Iterator> for details.

=head2 delete

  my $result = $self->delete();

Delete the given object.

=head1 INTERNAL METHODS

=head2 send_request

  my $response_data = $self->send_request( $args );

Turn the args into xml, send it to FreshBooks, receive back the XML and
convert it back into a Perl data structure.

=head2 method_string

  my $method_string = $self->method_string( 'action' );

Returns a method string for this class - something like 'client.action'.

=head2 api_name

  my $api_name = $self->api_name(  );

Returns the name that should be used in the API for this class.

=head2 node_name

  my $node_name = $self->node_name(  );

Returns the name that should be used in the XML nodes for this class. Normally
this is the same as the C<api_name> but can be overridden if needed.

=head2 id_field

  my $id_field = $self->id_field(  );

Returns the id field for this class.

=head2 field_names

  my @names = $self->field_names();

Return the names of all the fields.

=head2 field_names_rw

  my @names = $self->field_names_rw();

Return the names of all the fields that are marked as read and write.

=head2 parameters_to_request_xml

  my $xml = $self->parameters_to_request_xml( \%parameters );

Takes the parameters given and turns them into the xml that should be sent to
the server. This has some smarts that works around the tedium of processing
Perl datastructures -> XML. In particular any key starting with an underscore
becomes an attribute. Any key pointing to an array is wrapped so that it
appears correctly in the XML.

=head2 construct_element( $element, $hashref )

Requires an XML::LibXML::Element object, followed by a HASHREF of attributes,
text nodes, nested values or child elements or some combination thereof.

=head2 response_xml_to_node

  my $params = $self->response_xml_to_node( $xml );

Take XML from FB and turn it into a data structure that is easier to work with.

=head2 send_xml_to_freshbooks

  my $returned_xml = $self->send_xml_to_freshbooks( $xml_to_send );

Sends the XML to the FreshBooks API and returns the XML content returned. This
is the lowest part and is encapsulated here so that it can be easily
overridden for testing.

=head1 AUTHORS

=over 4

=item *

Edmund von der Burg <evdb@ecclestoad.co.uk>

=item *

Olaf Alders <olaf@wundercounter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edmund von der Burg & Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
