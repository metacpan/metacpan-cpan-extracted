package Net::Async::Webservice::UPS::Response::Address;
$Net::Async::Webservice::UPS::Response::Address::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::Address::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Types::Standard qw(ArrayRef HashRef);
use Net::Async::Webservice::UPS::Types qw(:types);
use namespace::autoclean;

extends 'Net::Async::Webservice::UPS::Response';

# ABSTRACT: response for validate_address


has addresses => (
    is => 'ro',
    isa => ArrayRef[Address],
    required => 1,
);

sub BUILDARGS {
    my ($class,$hashref) = @_;
    if (@_>2) { shift; $hashref={@_} };

    my $ret = $class->next::method($hashref);

    if ($hashref->{addresses} and not $ret->{addresses}) {
        $ret->{addresses} = $hashref->{addresses};
    }

    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::Address - response for validate_address

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

Instances of this class are returned (in the Future) by calls to
L<Net::Async::Webservice::UPS/validate_address>.

=head1 ATTRIBUTES

=head2 C<addresses>

Array ref of addresses that correspond to the one passed in to
C<validate_address>. Each one will have its own C<quality> rating.

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
