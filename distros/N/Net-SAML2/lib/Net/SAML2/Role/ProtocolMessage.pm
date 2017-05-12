package Net::SAML2::Role::ProtocolMessage;
use Moose::Role;
use MooseX::Types::Moose qw/ Str /;
use DateTime::Format::XSD;
use Crypt::OpenSSL::Random;
use XML::Generator;

=head1 NAME

Net::SAML2::Role::ProtocolMessage - common behaviour for Protocol messages

=head1 DESCRIPTION

Provides default ID and timestamp arguments for Protocol classes.

Provides a status-URI lookup method for the statuses used by this
implementation.

=cut

has 'id'            => (isa => Str, is => 'ro', required => 1);
has 'issue_instant' => (isa => Str, is => 'ro', required => 1);

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $class = shift;      
    my %args = @_;

    # random ID for this message
    $args{id} ||= unpack 'H*', Crypt::OpenSSL::Random::random_pseudo_bytes(16);

    # IssueInstant in UTC
    my $dt = DateTime->now( time_zone => 'UTC' );
    $args{issue_instant} ||= $dt->strftime('%FT%TZ');
        
    return \%args;
};

=head1 METHODS

=head2 status_uri($status)

Provides a mapping from short names for statuses to the full status URIs.

=cut

sub status_uri {
    my ($self, $status) = @_;

    my $statuses = {
        success   => 'urn:oasis:names:tc:SAML:2.0:status:Success',
        requester => 'urn:oasis:names:tc:SAML:2.0:status:Requester',
        responder => 'urn:oasis:names:tc:SAML:2.0:status:Responder',
    };

    if (exists $statuses->{$status}) {
        return $statuses->{$status};
    }

    return;
}

1;
