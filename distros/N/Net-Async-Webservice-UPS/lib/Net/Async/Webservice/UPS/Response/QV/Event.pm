package Net::Async::Webservice::UPS::Response::QV::Event;
$Net::Async::Webservice::UPS::Response::QV::Event::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::QV::Event::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use 5.010;
use Types::Standard qw(Str ArrayRef HashRef);
use Net::Async::Webservice::UPS::Types qw(:types);
use Net::Async::Webservice::UPS::Response::Utils ':all';
use Types::DateTime DateTime => { -as => 'DateTimeT' };
use DateTime::Format::Strptime;
use namespace::autoclean;

# ABSTRACT: a Quantum View "event"


has name => (
    is => 'ro',
    isa => Str,
    required => 1,
);


has number => (
    is => 'ro',
    isa => Str,
    required => 1,
);


has status => (
    is => 'ro',
    isa => HashRef,
    required => 1,
);


has files => (
    is => 'ro',
    isa => ArrayRef[QVFile],
    required => 1,
);


has begin_date => (
    is => 'ro',
    isa => DateTimeT,
    required => 0,
);


has end_date => (
    is => 'ro',
    isa => DateTimeT,
    required => 0,
);

sub BUILDARGS {
    my ($class,$hashref) = @_;
    if (@_>2) { shift; $hashref={@_} };

    if ($hashref->{Name}) {
        state $date_parser = DateTime::Format::Strptime->new(
            pattern => '%Y%m%d%H%M%S',
        );
        set_implied_argument($hashref);

        return {
            in_if(name=>'Name'),
            in_if(number=>'Number'),
            in_if(status=>'SubscriptionStatus'),
            ( $hashref->{DateRange}{BeginDate} ? ( begin_date => $date_parser->parse_datetime($hashref->{DateRange}{BeginDate}) ) : () ),
            ( $hashref->{DateRange}{EndDate} ? ( end_date => $date_parser->parse_datetime($hashref->{DateRange}{EndDate}) ) : () ),
            in_object_array_if(files=>'SubscriptionFile','Net::Async::Webservice::UPS::Response::QV::File'),
        };
    }
    return $hashref;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::QV::Event - a Quantum View "event"

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

Object representing the C<QuantumViewEvents/SubscriptionEvents>
elements in the Quantum View response. Attribute descriptions come
from the official UPS documentation.

=head1 ATTRIBUTES

=head2 C<name>

String, a name uniquely defined associated to the Subscription ID, for
each subscription.

=head2 C<number>

String, a number uniquely defined associated to the Subscriber ID, for
each subscription.

=head2 C<status>

Hashref, with keys:

=over 4

=item C<Code>

required, status types of subscription; valid values are: C<UN> – Unknown, C<AT> – Activate, C<P> – Pending, C<A> –Active, C<I> – Inactive, C<S> - Suspended

=item C<Description>

optional, description of the status

=back

=head2 C<files>

Array ref of L<Net::Async::Webservice::UPS::Response::QV::File>

=head2 C<begin_date>

Optional, beginning date-time of subscription requested by user. It's
a L<DateTime> object, most probably with a floating timezone.

=head2 C<end_date>

Optional, ending date-time of subscription requested by user. It's a
L<DateTime> object, most probably with a floating timezone.

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
