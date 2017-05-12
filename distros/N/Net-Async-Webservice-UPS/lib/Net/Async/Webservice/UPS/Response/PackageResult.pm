package Net::Async::Webservice::UPS::Response::PackageResult;
$Net::Async::Webservice::UPS::Response::PackageResult::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::PackageResult::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Types::Standard qw(Str);
use Net::Async::Webservice::UPS::Types qw(:types);
use Net::Async::Webservice::UPS::Response::Utils ':all';
use namespace::autoclean;

# ABSTRACT: information about a package in a booked shipment


has tracking_number => (
    is => 'ro',
    isa => Str,
    required => 1,
);


has currency => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has service_option_charges => (
    is => 'ro',
    isa => Measure,
    required => 0,
);


has label => (
    is => 'ro',
    isa => Image,
    required => 0,
);


has signature => (
    is => 'ro',
    isa => Image,
    required => 0,
);


has html => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has pdf417 => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has receipt => (
    is => 'ro',
    isa => Image,
    required => 0,
);


has form_code => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has form_image => (
    is => 'ro',
    isa => Image,
    required => 0,
);


has form_group_id => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has cod_turn_in => (
    is => 'ro',
    isa => Image,
    required => 0,
);


has package => (
    is => 'ro',
    isa => Package,
    required => 1,
);

sub BUILDARGS {
    my ($class,@etc) = @_;
    my $ret = $class->next::method(@etc);

    if ($ret->{TrackingNumber}) {
        set_implied_argument($ret);
        return {
            package => $ret->{package},
            tracking_number => $ret->{TrackingNumber},
            currency => $ret->{ServiceOptionsCharges}{CurrencyCode},
            service_option_charges => $ret->{ServiceOptionsCharges}{MonetaryValue},
            img_if( label => $ret->{LabelImage} ),
            ( $ret->{LabelImage}{InternationalSignatureGraphicImage} ?
                  ( signature => Net::Async::Webservice::UPS::Response::Image->new({
                      format => $ret->{LabelImage}{ImageFormat}{Code},
                      base64_data => $ret->{LabelImage}{InternationalSignatureGraphicImage},
                  }) ) : () ),
            base64_if( html => $ret->{LabelImage}{HTMLImage} ),
            base64_if( pdf417 => $ret->{LabelImage}{PDF417} ),
            img_if( receipt => $ret->{Receipt}{Image} ),
            img_if( form_image => $ret->{Form} ),
            pair_if( form_code => $ret->{Form}{Code} ),
            pair_if( form_group_id => $ret->{FormGroupId} ),
            img_if( cod_turn_in => $ret->{CODTurnInPage} ),
        };
    }
    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::PackageResult - information about a package in a booked shipment

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

Instances of this class are returned as part of
L<Net::Async::Webservice::UPS::Response::ShipmentAccept> by
L<Net::Async::Webservice::UPS/ship_accept>.

=head1 ATTRIBUTES

=head2 C<tracking_number>

String, tracking code for this package.

=head2 C<currency>

String, the currency code for all the charges.

=head2 C<service_option_charges>

Number, how much the service option costs (in L</currency>) for this package.

=head2 L<label>

An instance of L<Net::Async::Webservice::UPS::Response::Image>, label
to print for this package.

=head2 L<signature>

An instance of L<Net::Async::Webservice::UPS::Response::Image>, not
sure what this is for.

=head2 L<html>

HTML string, not sure what this is for.

=head2 L<pdf417>

String of bytes containing a PDF417 barcode, not sure what this is for.

=head2 L<receipt>

An instance of L<Net::Async::Webservice::UPS::Response::Image>, not
sure what this is for.

=head2 C<form_code>

String, not sure what this is for.

=head2 L<form_image>

An instance of L<Net::Async::Webservice::UPS::Response::Image>, not
sure what this is for.

=head2 C<form_group_id>

String, not sure what this is for.

=head2 C<cod_turn_in>

An instance of L<Net::Async::Webservice::UPS::Response::Image>, not
sure what this is for.

=head2 C<package>

Reference to the package given to the
L<Net::Async::Webservice::UPS/ship_confirm> request, to which this
result element refers to.

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
