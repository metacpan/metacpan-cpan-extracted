package Net::Async::Webservice::DHL::Address;
use Moo;
use 5.010;
use Types::Standard qw(Str Int Bool StrictNum);
use Net::Async::Webservice::DHL::Types ':types';
our $VERSION = '1.2.2'; # VERSION

# ABSTRACT: an address for DHL


for my $l (1..3) {
    has "line$l" => (
        is => 'ro',
        isa => Str,
        required => 0,
    );
}


has city => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has division => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has postal_code => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has country_code => (
    is => 'ro',
    isa => CountryCode,
    required => 1,
);


has country_name => (
    is => 'ro',
    isa => Str,
    required => 0,
);


sub as_hash {
    my ($self,$shape) = @_;
    my $if = sub {
        my ($method,$key) = @_;
        if ($self->$method) {
            return ( $key => $self->$method );
        }
        return;
    };

    if ($shape eq 'capability') {
        return {
            $if->(postal_code => 'Postalcode'),
            $if->(city => 'City'),
            CountryCode => $self->country_code,
        };
    }
    elsif ($shape eq 'route') {
        return {
            $if->(line1 => 'Address1'),
            $if->(line2 => 'Address2'),
            $if->(line3 => 'Address3'),
            $if->(postal_code => 'PostalCode'),
            $if->(city => 'City'),
            $if->(division => 'Division'),
            CountryCode => $self->country_code,
            CountryName => '', # the value is required, but an empty
                               # string will do
            $if->(country_name => 'CountryName'),
        };
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::DHL::Address - an address for DHL

=head1 VERSION

version 1.2.2

=head1 ATTRIBUTES

=head2 C<line1>

=head2 C<line2>

=head2 C<line3>

Address lines, all optional strings.

=head2 C<city>

String with the name of the city, optional.

=head2 C<division>

Code of the division (e.g. state, prefecture, etc.), optional string.

=head2 C<postal_code>

String with the post code of the address, optional.

=head2 C<country_code>

String with the 2 letter country code, required.

=head2 C<country_name>

String with the full country name, required only for some uses.

=head1 METHODS

=head2 C<as_hash>

Returns a hashref that, when passed through L<XML::Compile>, will
produce the XML fragment needed in DHL requests to represent this
address.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Net-a-porter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
