package Net::SAML2::Protocol::AuthnRequest;
use Moose;

our $VERSION = '0.76'; # VERSION
use MooseX::Types::URI            qw/ Uri /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use XML::Generator;
use List::Util        qw(any);
use URN::OASIS::SAML2 qw(:urn BINDING_HTTP_POST);

with 'Net::SAML2::Role::ProtocolMessage';

# ABSTRACT: SAML2 AuthnRequest object



has 'nameid' => (
    isa       => NonEmptySimpleStr,
    is        => 'rw',
    predicate => 'has_nameid'
);

has 'nameidpolicy_format' => (
    isa       => 'Str',
    is        => 'rw',
    predicate => 'has_nameidpolicy_format'
);

has 'nameid_allow_create' => (
    isa       => 'Bool',
    is        => 'rw',
    required  => 0,
    predicate => 'has_nameid_allow_create'
);

has 'assertion_url' => (
    isa       => Uri,
    is        => 'rw',
    coerce    => 1,
    predicate => 'has_assertion_url',
);

has 'assertion_index' => (
    isa       => 'Int',
    is        => 'rw',
    predicate => 'has_assertion_index',
);

has 'attribute_index' => (
    isa       => 'Int',
    is        => 'rw',
    predicate => 'has_attribute_index',
);

has 'protocol_binding' => (
    isa       => Uri,
    is        => 'rw',
    coerce    => 1,
    predicate => 'has_protocol_binding',
);
has 'provider_name' => (
    isa       => 'Str',
    is        => 'rw',
    predicate => 'has_provider_name',
);

has 'AuthnContextClassRef' => (
    isa     => 'ArrayRef[Str]',
    is      => 'rw',
    default => sub { [] }
);

has 'AuthnContextDeclRef' => (
    isa     => 'ArrayRef[Str]',
    is      => 'rw',
    default => sub { [] }
);

has 'RequestedAuthnContext_Comparison' => (
    isa     => 'Str',
    is      => 'rw',
    default => 'exact'
);

has 'force_authn' => (
    isa       => 'Bool',
    is        => 'ro',
    predicate => 'has_force_authn',
);

has 'is_passive' => (
    isa       => 'Bool',
    is        => 'ro',
    predicate => 'has_is_passive',
);

has identity_providers => (
    isa       => 'ArrayRef[Str]',
    is        => 'ro',
    predicate => 'has_identity_providers',
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;

    my %params = @_;
    if ($params{nameid_format} && !defined $params{nameidpolicy_format}) {
        $params{nameidpolicy_format} = $params{nameid_format};
    }

    return $self->$orig(%params);
};


my $samlp = ['samlp' => URN_PROTOCOL];
my $saml  = ['saml' => URN_ASSERTION];

sub as_xml {
    my ($self) = @_;

    my $x = XML::Generator->new(':std');

    my %req_atts = (
        ID           => $self->id,
        IssueInstant => $self->issue_instant,
        Version      => '2.0',
    );

    my %issuer_attrs = ();

    my %protocol_bindings
        = ('HTTP-POST' => BINDING_HTTP_POST);

    my %att_map = (
        'assertion_url'        => 'AssertionConsumerServiceURL',
        'assertion_index'      => 'AssertionConsumerServiceIndex',
        'attribute_index'      => 'AttributeConsumingServiceIndex',
        'protocol_binding'     => 'ProtocolBinding',
        'provider_name'        => 'ProviderName',
        'destination'          => 'Destination',
        'issuer_namequalifier' => 'NameQualifier',
        'issuer_format'        => 'Format',
        'force_authn'          => 'ForceAuthn',
        'is_passive'           => 'IsPassive',
    );

    my @opts = qw(
        assertion_url assertion_index protocol_binding
        attribute_index provider_name destination
        force_authn is_passive
    );

    foreach my $opt (@opts) {
        my $predicate = 'has_' . $opt;
        next if !$self->can($predicate) || !$self->$predicate;

        my $val = $self->$opt;
        if ($opt eq 'protocol_binding') {
            $req_atts{ $att_map{$opt} } = $protocol_bindings{$val};
        }
        elsif (any { $opt eq $_ } qw(force_authn is_passive)) {
            $req_atts{ $att_map{$opt} } = ($val ? 'true' : 'false');
        }
        else {
            $req_atts{ $att_map{$opt} } = $val;
        }
    }

    foreach my $opt (qw(issuer_namequalifier issuer_format)) {
        my $predicate = 'has_' . $opt;
        next if !$self->can($predicate) || !$self->$predicate;

        my $val = $self->$opt;
        $issuer_attrs{ $att_map{$opt} } = $val;
    }

    return $x->AuthnRequest($samlp,
        \%req_atts,
        $x->Issuer($saml, \%issuer_attrs, $self->issuer),
        $self->_set_name_id($x),
        $self->_set_name_policy_format($x),
        $self->_set_requested_authn_context($x),
        $self->_set_scoping($x),
    );

}

sub _set_scoping {
    my $self = shift;
    return unless $self->has_identity_providers;
    my $x = shift;

    my @providers = map { $x->IDPEntry($samlp, { ProviderID => $_ }) }
        @{ $self->identity_providers };
    return $x->Scoping($samlp, $x->IDPList($samlp, @providers));
}

sub _set_name_id {
    my $self = shift;
    return unless $self->has_nameid;
    my $x = shift;
    return $x->Subject($saml, $x->NameID($saml, {NameQualifier => $self->nameid}));
}

sub _set_name_policy_format {
    my $self = shift;
    return unless $self->has_nameidpolicy_format;
    my $x = shift;
    return $x->NameIDPolicy(
        $samlp,
        {
            Format => $self->nameidpolicy_format,
            $self->has_nameid_allow_create
            ? (AllowCreate => $self->nameid_allow_create)
            : (),
        }
    );

}

sub _set_requested_authn_context {
    my ($self, $x) = @_;

    return
        if !@{ $self->AuthnContextClassRef }
        && !@{ $self->AuthnContextDeclRef };

    my @class = map { $x->AuthnContextClassRef($saml, undef, $_) }
        @{ $self->AuthnContextClassRef };

    my @decl = map { $x->AuthnContextDeclRef($saml, undef, $_) }
        @{ $self->AuthnContextDeclRef };

    return $x->RequestedAuthnContext(
        $samlp,
        { Comparison => $self->RequestedAuthnContext_Comparison },
        @class, @decl
    );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Protocol::AuthnRequest - SAML2 AuthnRequest object

=head1 VERSION

version 0.76

=head1 SYNOPSIS

  my $authnreq = Net::SAML2::Protocol::AuthnRequest->new(
    id            => 'NETSAML2_Crypt::OpenSSL::Random::random_pseudo_bytes(16),
    issuer        => $self->{id},	# Service Provider (SP) Entity ID
    destination   => $destination,	# Identity Provider (IdP) SSO URL
    provider_name => $provider_name,	# Service Provider (SP) Human Readable Name
    issue_instant => DateTime->now,	# Defaults to Current Time
    force_authn   => $force_authn,	# Force new authentication (Default: false)
    is_passive    => $is_passive,	# IdP should not take control of UI (Default: false)
  );

  my $request_id = $authnreq->id;	# Store and Compare to InResponseTo

  or

  my $request_id = 'NETSAML2_' . unpack 'H*', Crypt::OpenSSL::Random::random_pseudo_bytes(16);

  my $authnreq = Net::SAML2::Protocol::AuthnRequest->as_xml(
    id            => $request_id,	# Unique Request ID will be returned in response
    issuer        => $self->{id},	# Service Provider (SP) Entity ID
    destination   => $destination,	# Identity Provider (IdP) SSO URL
    provider_name => $provider_name,	# Service Provider (SP) Human Readable Name
    issue_instant => DateTime->now,	# Defaults to Current Time
    force_authn   => $force_authn,	# Force new authentication (Default: false)
    is_passive    => $is_passive,	# IdP should not take control of UI (Default: false)
  );

=head1 NAME

Net::SAML2::Protocol::AuthnRequest - SAML2 AuthnRequest object

=head1 METHODS

=head2 new( ... )

Constructor. Creates an instance of the AuthnRequest object.

Important Note: Best practice is to always do this first.  While it is possible
to call C<as_xml()> first you do not have to set the id as it will be set for you
automatically.

However tracking the id is important for security to ensure that the response
has the same id in the InResponseTo attribute.

Arguments:

=over

=item nameidpolicy_format

Format attribute for NameIDPolicy

=item AuthnContextClassRef, <AuthnContextDeclRef

Each one is an arrayref containing values for AuthnContextClassRef and
AuthnContextDeclRef.  If any is populated, the RequestedAuthnContext will be
included in the request.

=item RequestedAuthnContext_Comparison

Value for the I<Comparison> attribute in case I<RequestedAuthnContext> is
included (see above). Default value is I<exact>.

=item identity_providers

An arrayref of Identity providers, if used the Scoping element is added to the
XML

=back

=head2 as_xml( )

Returns the AuthnRequest as XML.

=head1 AUTHORS

=over 4

=item *

Chris Andrews  <chrisa@cpan.org>

=item *

Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
