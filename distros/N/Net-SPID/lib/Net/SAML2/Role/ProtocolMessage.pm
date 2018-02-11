package Net::SAML2::Role::ProtocolMessage;
$Net::SAML2::Role::ProtocolMessage::VERSION = '0.12';
use Moose::Role;
use MooseX::Types::Moose qw/ Str /;
use MooseX::Types::URI qw/ Uri /;
use DateTime::Format::XSD;
use Crypt::OpenSSL::Random;
use XML::Generator;


has 'id'            => (isa => Str, is => 'ro', required => 1);
has 'issue_instant' => (isa => Str, is => 'ro', required => 1);
has 'issuer'        => (isa => Uri, is => 'rw', required => 1, coerce => 1);
has 'issuer_namequalifier' => (isa => Str, is => 'rw', required => 0);
has 'issuer_format' => (isa => Str, is => 'rw', required => 0);
has 'destination'   => (isa => Uri, is => 'rw', required => 0, coerce => 1);

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


sub status_uri {
    my ($self, $status) = @_;

    my $statuses = {
        success   => 'urn:oasis:names:tc:SAML:2.0:status:Success',
        requester => 'urn:oasis:names:tc:SAML:2.0:status:Requester',
        responder => 'urn:oasis:names:tc:SAML:2.0:status:Responder',
        partial   => 'urn:oasis:names:tc:SAML:2.0:status:PartialLogout',
    };

    if (exists $statuses->{$status}) {
        return $statuses->{$status};
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Role::ProtocolMessage

=head1 VERSION

version 0.12

=head1 DESCRIPTION

Provides default ID and timestamp arguments for Protocol classes.

Provides a status-URI lookup method for the statuses used by this
implementation.

=head1 NAME

Net::SAML2::Role::ProtocolMessage - common behaviour for Protocol messages

=head1 CONSTRUCTOR ARGUMENTS

=over

=item B<issuer>

URI of issuer

=item B<issuer_namequalifier>

NameQualifier attribute for Issuer

=item B<issuer_format>

Format attribute for Issuer

=item B<destination>

URI of Destination

=back

=head1 METHODS

=head2 status_uri( $status )

Provides a mapping from short names for statuses to the full status URIs.

Legal short names for B<$status> are:

=over

=item C<success>

=item C<requester>

=item C<responder>

=back

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
