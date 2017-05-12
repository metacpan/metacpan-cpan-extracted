package Net::Async::Webservice::UPS::Response::QV;
$Net::Async::Webservice::UPS::Response::QV::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::QV::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Types::Standard qw(Str ArrayRef);
use Net::Async::Webservice::UPS::Types qw(:types);
use Net::Async::Webservice::UPS::Response::Utils ':all';
use namespace::autoclean;
extends 'Net::Async::Webservice::UPS::Response';

# ABSTRACT: response for qv_events


has subscriber_id => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has events => (
    is => 'ro',
    isa => ArrayRef[QVEvent],
    required => 0,
);


has bookmark => (
    is => 'ro',
    isa => Str,
    required => 0,
);

sub BUILDARGS {
    my ($class,$hashref) = @_;
    if (@_>2) { shift; $hashref={@_} };

    my $ret = $class->next::method($hashref);

    if ($hashref->{QuantumViewEvents}) {
        my $data = $hashref->{QuantumViewEvents};
        set_implied_argument($data);
        $ret = {
            %$ret,
            in_object_array_if(events => 'SubscriptionEvents', 'Net::Async::Webservice::UPS::Response::QV::Event' ),
            subscriber_id => $data->{SubscriberID},
            pair_if(bookmark => $hashref->{Bookmark}),
        };
    }
    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::QV - response for qv_events

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

Instances of this class are returned (in the Future) by calls to
L<Net::Async::Webservice::UPS/qv_events>.

=head1 ATTRIBUTES

=head2 C<subscriber_id>

The UPS Quantum View subscriber id. It's the same as the UPS user id.

=head2 C<events>

Array ref of L<Net::Async::Webservice::UPS::Response::QV::Event>

=head2 C<bookmark>

String used to paginate long results. Use it like this:

  use feature 'current_sub';

  $ups->qv_events($args)->then(sub {
   my ($response) = @_;
   do_something_with($response);
   if ($response->bookmark) {
     $args->{bookmark} = $response->bookmark;
     return $ups->qv_events($args)->then(__SUB__);
   }
   else {
    return Future->done()
   }
  });

So:

=over 4

=item *

a response without a bookmark is the last one

=item *

if there is a bookmark, a new request must be performed with the same subscriptions, plus the bookmark

=back

(yes, the example requires Perl 5.16, but that's just to make it
compact)

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
