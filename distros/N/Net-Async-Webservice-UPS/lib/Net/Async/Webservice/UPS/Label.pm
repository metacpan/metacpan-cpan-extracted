package Net::Async::Webservice::UPS::Label;
$Net::Async::Webservice::UPS::Label::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Label::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use 5.010;
use Net::Async::Webservice::UPS::Types qw(:types);
use namespace::autoclean;

# ABSTRACT: a label for a shipment request


has code => (
    is => 'ro',
    isa => ImageType,
    required => 1,
);


sub as_hash {
    my ($self) = @_;

    return {
        LabelPrintMethod => {
            Code => $self->code,
        },
        ( $self->code eq 'GIF' ? (
            HTTPUserAgent => 'Mozilla/4.5',
            LabelImageFormat => 'GIF',
        ) : (
            LabelStockSize => {
                Height => 4,
                Width => 6,
            },
        ) ),
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Label - a label for a shipment request

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

This class is to be used in
L<Net::Async::Webservice::UPS/ship_confirm> to specify what kind of
label you want in the response.

=head1 ATTRIBUTES

=head2 C<code>

Required, enum of type
L<Net::Async::Webservice::UPS::Types/ImageType>, one of C<EPL>,
C<ZPL>, C<SPL>, C<STARPL>, C<GIF>.

=head1 METHODS

=head2 C<as_hash>

Returns a hashref that, when passed through L<XML::Simple>, will
produce the XML fragment needed in UPS requests to represent this
label. C<GIF> labels get a C<UserAgent> value of C<Mozilla/4.5>, and
others get a C<LabelStockSize> of 4" by 6": that's what I think the
UPS documentation say is required.

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
