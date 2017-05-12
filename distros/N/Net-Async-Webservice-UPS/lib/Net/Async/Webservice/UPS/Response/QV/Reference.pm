package Net::Async::Webservice::UPS::Response::QV::Reference;
$Net::Async::Webservice::UPS::Response::QV::Reference::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::QV::Reference::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Types::Standard qw(Str ArrayRef HashRef);
use Net::Async::Webservice::UPS::Types qw(:types);
use Net::Async::Webservice::UPS::Response::Utils qw(:all);
use namespace::autoclean;

# ABSTRACT: a Quantum View package or shipment reference


has number => (
    is => 'ro',
    isa => Str,
);


has code => (
    is => 'ro',
    isa => Str,
);


has value => (
    is => 'ro',
    isa => Str,
);

sub BUILDARGS {
    my ($class,$hashref) = @_;
    if (@_>2) { shift; $hashref={@_} };

    if ($hashref->{Number}) {
        set_implied_argument($hashref);
        return {
            in_if(number=>'Number'),
            in_if(code=>'Code'),
            in_if(value=>'Value'),
        };
    }
    return $hashref;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::QV::Reference - a Quantum View package or shipment reference

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

Object representing the C<PackageReferenceNumber> or
C<ShipmentReferenceNumber> elements in the Quantum View
response. Attribute descriptions come from the official UPS
documentation.

=head1 ATTRIBUTES

=head2 C<number>

Optional string, number tag.

=head2 C<code>

Optional string, reflects what will go on the label as the name of the
reference.

=head2 C<value>

Optional string, customer supplied reference number. Reference numbers
are defined by the shipper and can contain any character string.

=for Pod::Coverage BUILDARGS

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
