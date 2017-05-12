package Net::Async::Webservice::UPS::Response::QV::File;
$Net::Async::Webservice::UPS::Response::QV::File::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::QV::File::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Types::Standard qw(Str ArrayRef HashRef);
use Net::Async::Webservice::UPS::Types qw(:types);
use Net::Async::Webservice::UPS::Response::Utils ':all';
use namespace::autoclean;

# ABSTRACT: a Quantum View "file"


has filename => (
    is => 'ro',
    isa => Str,
    required => 1,
);


has status => (
    is => 'ro',
    isa => HashRef,
    required => 0,
);


has origins => (
    is => 'ro',
    isa => ArrayRef[QVOrigin],
    required => 0,
);


has generics => (
    is => 'ro',
    isa => ArrayRef[QVGeneric],
    required => 0,
);


has manifests => (
    is => 'ro',
    isa => ArrayRef[QVManifest],
    required => 0,
);


has deliveries => (
    is => 'ro',
    isa => ArrayRef[QVDelivery],
    required => 0,
);


has exceptions => (
    is => 'ro',
    isa => ArrayRef[QVException],
    required => 0,
);

sub BUILDARGS {
    my ($class,$hashref) = @_;
    if (@_>2) { shift; $hashref={@_} };

    if ($hashref->{FileName}) {
        set_implied_argument($hashref);

        return {
            in_if(filename => 'FileName'),
            in_if(status => 'StatusType'),
            in_object_array_if(origins=>'Origin','Net::Async::Webservice::UPS::Response::QV::Origin'),
            in_object_array_if(generics=>'Generic','Net::Async::Webservice::UPS::Response::QV::Generic'),
            in_object_array_if(deliveries=>'Delivery','Net::Async::Webservice::UPS::Response::QV::Delivery'),
            # Manifests are not yet supported
            #in_object_array_if(manifests=>'Manifest','Net::Async::Webservice::UPS::Response::QV::Manifest'),
            in_object_array_if(exceptions=>'Exception','Net::Async::Webservice::UPS::Response::QV::Exception'),
        };
    }
    return $hashref;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::QV::File - a Quantum View "file"

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

Object representing the
C<QuantumViewEvents/SubscriptionEvents/SubscriptionFile> elements in
the Quantum View response. Attribute descriptions come from the
official UPS documentation.

=head1 ATTRIBUTES

=head2 C<filename>

File name belonging to specific subscription requested by user,
usually in form of C<YYMMDD_HHmmssnnn>.

=head2 C<status>

Hashref, with keys:

=over 4

=item C<Code>

required, status types of subscription file; valid values are: C<R> – Read, C<U> - Unread

=item C<Description>

optional, description of the status

=back

=head2 C<origins>

Optional, array ref of L<Net::Async::Webservice::UPS::Response::QV::Origin>.

=head2 C<generics>

Optional, array ref of L<Net::Async::Webservice::UPS::Response::QV::Generic>.

=head2 C<manifests>

Optional, array ref of L<Net::Async::Webservice::UPS::Response::QV::Manifest>.

B<Never set in this version>. Parsing manifests is complicated, it
will be maybe implemented in a future version.

=head2 C<deliveries>

Optional, array ref of L<Net::Async::Webservice::UPS::Response::QV::Delivery>.

=head2 C<exceptions>

Optional, array ref of L<Net::Async::Webservice::UPS::Response::QV::Exception>.

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
