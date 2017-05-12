package Net::SAML2::Protocol::Assertion;
use Moose;
use MooseX::Types::Moose qw/ Str HashRef ArrayRef /;
use MooseX::Types::DateTime qw/ DateTime /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use DateTime;
use DateTime::Format::XSD;

with 'Net::SAML2::Role::ProtocolMessage';

=head1 NAME

Net::SAML2::Protocol::Assertion - SAML2 assertion object

=head1 SYNOPSIS

  my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
    xml => decode_base64($SAMLResponse)
  );

=cut

has 'attributes' => (isa => HashRef[ArrayRef], is => 'ro', required => 1);
has 'session'    => (isa => Str, is => 'ro', required => 1);
has 'nameid'     => (isa => Str, is => 'ro', required => 1);
has 'not_before' => (isa => DateTime, is => 'ro', required => 1);
has 'not_after'  => (isa => DateTime, is => 'ro', required => 1);
has 'audience'   => (isa => NonEmptySimpleStr, is => 'ro', required => 1);

=head1 METHODS

=cut

=head2 new_from_xml( ... )

Constructor. Creates an instance of the Assertion object, parsing the
given XML to find the attributes, session and nameid. 

=cut

sub new_from_xml { 
    my ($class, %args) = @_;

    my $xpath = XML::XPath->new( xml => $args{xml} );
    $xpath->set_namespace('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');

    my $attributes = {};
    for my $node ($xpath->findnodes('//saml:Assertion/saml:AttributeStatement/saml:Attribute')) {
        my @values = $node->findnodes('saml:AttributeValue');
        $attributes->{$node->getAttribute('Name')} = [
            map { $_->string_value } @values
        ];
    }
        
    my $not_before = DateTime::Format::XSD->parse_datetime(
        $xpath->findvalue('//saml:Conditions/@NotBefore')->value
    );
    my $not_after = DateTime::Format::XSD->parse_datetime(
        $xpath->findvalue('//saml:Conditions/@NotOnOrAfter')->value
    );

    my $self = $class->new(
        attributes     => $attributes,
        session        => $xpath->findvalue('//saml:AuthnStatement/@SessionIndex')->value,
        nameid         => $xpath->findvalue('//saml:Subject/saml:NameID')->value,
        audience       => $xpath->findvalue('//saml:Conditions/saml:AudienceRestriction/saml:Audience')->value,
        not_before     => $not_before,
        not_after      => $not_after,
    );
        
    return $self;
}

=head2 name

Returns the CN attribute, if provided.

=cut

sub name {
    my ($self) = @_;
    return $self->attributes->{CN}->[0];
}

=head2 valid( $audience )

Returns true if this Assertion is currently valid for the given audience.

Checks the audience matches, and that the current time is within the
Assertions validity period as specified in its Conditions element.

=cut

sub valid {
    my ($self, $audience) = @_;

    return 0 unless defined $audience;
    return 0 unless ($audience eq $self->audience);

    my $now = DateTime::->now;
        
    # not_before is "NotBefore" element - exact match is ok
    # not_after is "NotOnOrAfter" element - exact match is *not* ok
    return 0 unless DateTime::->compare($now, $self->not_before) > -1;
    return 0 unless DateTime::->compare($self->not_after, $now) > 0;

    return 1;
}

1;
