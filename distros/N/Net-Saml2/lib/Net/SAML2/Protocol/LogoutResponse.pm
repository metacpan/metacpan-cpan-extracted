package Net::SAML2::Protocol::LogoutResponse;
use Moose;
use MooseX::Types::URI qw/ Uri /;
use Net::SAML2::XML::Util qw/ no_comments /;

with 'Net::SAML2::Role::ProtocolMessage';


has 'status'      => (isa => 'Str', is => 'ro', required => 1);
has 'substatus'   => (isa => 'Str', is => 'ro', required => 0);
has 'response_to' => (isa => 'Str', is => 'ro', required => 1);


sub new_from_xml {
    my ($class, %args) = @_;

    my $xpath = XML::XPath->new( xml => no_comments($args{xml}) );
    $xpath->set_namespace('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');
    $xpath->set_namespace('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');

    my $self = $class->new(
        id          => $xpath->findvalue('/samlp:LogoutResponse/@ID')->value,
        response_to => $xpath->findvalue('/samlp:LogoutResponse/@InResponseTo')->value,
        destination => $xpath->findvalue('/samlp:LogoutResponse/@Destination')->value,
        session     => $xpath->findvalue('/samlp:LogoutResponse/samlp:SessionIndex')->value,
        issuer      => $xpath->findvalue('/samlp:LogoutResponse/saml:Issuer')->value,
        status      => $xpath->findvalue('/samlp:LogoutResponse/samlp:Status/samlp:StatusCode/@Value')->value,
        substatus   => $xpath->findvalue('/samlp:LogoutResponse/samlp:Status/samlp:StatusCode/samlp:StatusCode/@Value')->value,
    );

    return $self;
}


sub as_xml {
    my ($self) = @_;

    my $x = XML::Generator->new(':pretty');
    my $saml  = ['saml' => 'urn:oasis:names:tc:SAML:2.0:assertion'];
    my $samlp = ['samlp' => 'urn:oasis:names:tc:SAML:2.0:protocol'];

    $x->xml(
        $x->LogoutResponse(
            $samlp,
            { ID => $self->id,
              Version => '2.0',
              IssueInstant => $self->issue_instant,
              Destination => $self->destination,
              InResponseTo => $self->response_to },
            $x->Issuer(
                $saml,
                $self->issuer,
            ),
            $x->Status(
                $samlp,
                $x->StatusCode(
                    $samlp,
                    { Value => $self->status },
                )
            )
        )
    );
}


sub success {
    my ($self) = @_;
    return 1 if $self->status eq $self->status_uri('success');
    return 0;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Protocol::LogoutResponse

=head1 VERSION

version 0.29

=head1 SYNOPSIS

  my $logout_req = Net::SAML2::Protocol::LogoutResponse->new(
    issuer      => $issuer,
    destination => $destination,
    status      => $status,
    response_to => $response_to,
  );

=head1 NAME

Net::SAML2::Protocol::LogoutResponse - the SAML2 LogoutResponse object

=head1 METHODS

=head2 new( ... )

Constructor. Returns an instance of the LogoutResponse object.

Arguments:

=over

=item B<issuer>

SP's identity URI

=item B<destination>

IdP's identity URI

=item B<status>

response status

=item B<response_to>

request ID we're responding to

=back

=head2 new_from_xml( ... )

Create a LogoutResponse object from the given XML.

Arguments:

=over

=item B<xml>

XML data

=back

=head2 as_xml( )

Returns the LogoutResponse as XML.

=head2 success( )

Returns true if the Response's status is Success.

=head1 AUTHOR

Original Author: Chris Andrews  <chrisa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Chris Andrews and Others; in detail:

  Copyright 2010-2011  Chris Andrews
            2012       Peter Marschall
            2017       Alessandro Ranellucci
            2019       Timothy Legge
            2020       Timothy Legge, Wesley Schwengle


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
