package Net::Async::Webservice::UPS::Contact;
$Net::Async::Webservice::UPS::Contact::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Contact::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use 5.010;
use Types::Standard qw(Str);
use Net::Async::Webservice::UPS::Types ':types';
use Net::Async::Webservice::UPS::Address;
use namespace::autoclean;

# ABSTRACT: a "contact" for UPS


has name => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has company_name => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has attention_name => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has phone_number => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has email_address => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has address => (
    is => 'ro',
    isa => Address,
    required => 1,
);


sub as_hash {
    my ($self,$shape) = @_;

    $shape ||= 'Ship';

    return {
        ( $self->name ? ( Name => $self->name ) : () ),
        ( $self->company_name ? ( CompanyName => $self->company_name ) : () ),
        ( $self->attention_name ? ( AttentionName => $self->attention_name ) : () ),
        ( $self->phone_number ? ( PhoneNumber => $self->phone_number ) : () ),
        ( $self->email_address ? ( EmailAddress => $self->email_address ) : () ),
        %{ $self->address->as_hash($shape) },
    };
}


sub cache_id {
    my ($self) = @_;

    return $self->address->cache_id;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Contact - a "contact" for UPS

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

A contact is someone you send a shipment to, or that you want to pick
up a shipment from.

=head1 ATTRIBUTES

=head2 C<name>

Optional string, the contact's name.

=head2 C<company_name>

Optional string, the contact's company name.

=head2 C<attention_name>

Optional string, the name of the person to the attention of whom UPS
should bring the shipment.

=head2 C<phone_number>

Optional string, the contact's phone number.

=head2 C<email_address>

Optional string, the contact's email address.

=head2 C<address>

Required L<Net::Async::Webservice::UPS::Address> object, the contact's
address.

=head1 METHODS

=head2 C<as_hash>

Returns a hashref that, when passed through L<XML::Simple>, will
produce the XML fragment needed in UPS requests to represent this
contact.

=head2 C<cache_id>

Returns a string identifying this contact.

=head1 AUTHORS

=over 4

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=item *

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
