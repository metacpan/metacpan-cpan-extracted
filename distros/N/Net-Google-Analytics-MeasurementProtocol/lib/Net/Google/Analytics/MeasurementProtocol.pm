use v5.20;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use Carp ();
use JSON ();

our $VERSION = 4.01;

package Net::Google::Analytics::MeasurementProtocol {

  sub new ($class, %args) {
    return bless {
      api_secret     => $args{api_secret},
      measurement_id => $args{measurement_id},
      client_id      => $args{client_id} // _gen_uuid_v4(),
      agent          => $args{agent}     // _build_user_agent(),
      debug          => $args{debug},
      _route         => _build_route(%args),
    }, $class;
  }

  sub send ($self, $name, $properties) {
    Carp::croak('properties must be a hashref') unless ref $properties eq 'HASH';
    return $self->send_multiple( [{ $name => $properties }] );
  }

  sub send_multiple ($self, $events) {
    Carp::croak('events must be an array reference') unless ref $events eq 'ARRAY';
    my @formatted_events;
    foreach my $e (@$events) {
      my ($name, $params) = each %$e;
      push @formatted_events, { name => $name, params => $params }
    }

    my $payload = JSON::encode_json({
      client_id => $self->{client_id},
      events    => \@formatted_events,
    });

    my $res = $self->{agent}->post( $self->{_route}, $self->{agent}->isa('Furl') ? undef : (), $payload );
    if ($res->is_success) {
      return $self->{debug} ? JSON::decode_json($res->decoded_content) : 1;
    }
    return { __PACKAGE__ => $res->decoded_content };
  }

  sub _build_route(%args) {
    if ($args{tid}) {
      Carp::croak('Looks like you are calling ' . __PACKAGE__ . ' with'
          . ' outdated arguments from Universal Analytics. Please update'
          . ' to Google Analytics 4 (GA4) accordingly');
    }
    if (!$args{api_secret}) {
      Carp::croak('api_secret is required. Create one in Admin > Data Streams'
          . ' > choose your stream > Measurement Protocol > Create');
    }
    if (!$args{measurement_id}) {
      Carp::croak('measurement_id is required. Find yours under Admin > Data'
          . ' Streams > choose your stream > Measurement ID');
    }

    my $debug = $args{debug} ? '/debug' : '';
    return 'https://www.google-analytics.com' . $debug . '/mp/collect'
         . '?measurement_id=' . $args{measurement_id}
         . '&api_secret=' . $args{api_secret};
  }

  sub _build_user_agent {
    require Furl;
    return Furl->new( agent => __PACKAGE__ . '/' . $VERSION, timeout => 5, headers => ['Content-Type' => 'application/json'] );
  }

  # UUID v4 (pseudo-random) generator based on UUID::Tiny
  sub _gen_uuid_v4 {
    my $uuid = '';
    for ( 1 .. 4 ) {
        my ($v1, $v2) = (int(rand(65536)) % 65536, int(rand(65536)) % 65536);
        my $rand_32bit = ($v1 << 16) | $v2;
        $uuid .= pack 'I', $rand_32bit;
    }
    substr $uuid, 6, 1, chr( ord( substr( $uuid, 6, 1 ) ) & 0x0f | 0x40 );
    substr $uuid, 8, 1, chr( ord( substr( $uuid, 8, 1 ) ) & 0x3f | 0x80 );

    # uuid is created. Convert to string:
    return join '-', map { unpack 'H*', $_ } map { substr $uuid, 0, $_, '' } ( 4, 2, 2, 2, 6 );
  }
};

1;

__END__

=head1 NAME

Net::Google::Analytics::MeasurementProtocol - send Google Analytics (GA4) user interaction data from Perl

=head1 SYNOPSIS

    use Net::Google::Analytics::MeasurementProtocol;

    my $ga = Net::Google::Analytics::MeasurementProtocol->new(
        api_secret     => '...',
        measurement_id => '...',
    );

    $ga->send( level_up => { character => 'Alma', level => 99 } );

    $ga->send_multiple([
        {
            purchase => {
                transaction_id => 'T-1234',
                currency       => 'USD',
                value          => 14.99,
                coupon         => 'SPECIALPROMO',
                shipping       => 2.99,
                tax            => 0.37,
                items          => [
                    { item_id => 'X-1234', item_name => 'Amazing Tee' },
                    { item_id => 'Y-4321', item_name => 'Cool Shades' },
                ],
            },
        },
        {
            earn_virtual_currency => {
                virtual_currency_name => 'StoreCash',
                value => 999,
            },
        },
    ]);


=head1 DESCRIPTION

This is a Perl interface to L<Google Analytics Measurement Protocol|https://developers.google.com/analytics/devguides/collection/protocol/ga4>,
allowing developers to make HTTP requests to send raw user interaction data
directly to Google Analytics 4 (GA4) servers. It can be used to tie online
to offline behaviour, sending analytics data from both the web
(via JavaScript) and from the server (via this module).


=head1 WARNING - BACKWARDS INCOMPATIBLE

This distribution follows the next generation Google Analytics 4 (GA4),
which is completely different from previous versions like GA3 and Universal
Analytics (UA). As of 2023, Google has not only deprecated but
B<completely removed> these older versions of Analytics, and your code
(and ours) must adapt to theses changes. If you are upgrading, please
review your code.

=head1 CONSTRUCTOR

=head2 new( %options )

=head2 new( \%options )

    my $ga = Net::Google::Analytics::MeasurementProtocol->new(
        api_secret     => '...',
        measurement_id => '...',
    );

Creates a new object with the provided information. There are many options
to customize its behaviour:

=head3 Required parameters:

=over 4

=item * api_secret
String. This is the API Secret key generated manually via the Google
Analytics UI. To create one, go to:
Admin > Data Streams > choose your stream > Measurement Protocol API Secrets > Create

=item * measurement_id
String. This is the identifier for your target Data Stream. You can find
yours on the Google Analytics UI under:
Admin > Data Streams > choose your stream > Measurement ID

=back

=head3 Parameters with default values

=over 4

=item * agent
Object that handles requests/responses. May be a L<Furl> instance,
an L<LWP::UserAgent> instance, or anything that inherits from them,
like L<WWW::Mechanize>, or that provides a similar request/response
interface AND is able to handle HTTPS. Defaults to a L<Furl> instance.
Also, please make sure your object contains a default header of
'Content-Type' set to 'application/json'.

=item * client_id
String. Uniquely identify a user instance. B<Defaults to a random UUID>
created for this object (staying the same for as long as the object lives).

B<NOTE>: Google L<states|https://developers.google.com/analytics/devguides/collection/protocol/ga4/verify-implementation?client_type=gtag>
that events are only valid if they contain a I<< C<client_id> that has already been used to send an event from gtag.js >>.
While we haven't seen this constraint in our tests, you are probably better off setting this yourself.
Please see L<TROUBLESHOOTING|/TROUBLESHOOTING> for further information.

=back

=head3 Other parameters

There are many, I<many> parameters available. Please refer to the official
L<Measurement Protocol Parameter Reference|https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference?client_type=gtag> for details.

=head1 METHODS

=head2 send( $event_name, \%event_params )

Sends an event to Google Analytics (GA4). You may send any custom event name
or one of L<< Google's accepted events | https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference/events >> and their associated parameters.

B<NOTE:> This method will return a true value if the HTTP request to GA4
was properly received and false otherwise, but this DOES NOT MEAN the
event was accepted. The Measurement Protocol will not tell you if the
payload data was malformed, incorrect or not processed by Google Analytics
for whatever reason. See L<TROUBLESHOOTING|/TROUBLESHOOTING> for more
information on how to check if you are sending the proper data.

B<NOTE:> For your custom events to show up in standard GA4 reports
(like Realtime), you must pass the C<engagement_time_msec> and C<session_id>
parameters to the event. Ex:

    $ga->send( offline_purchase => { session_id => '123', engagement_time_msec => 100 } );


=head2 send_multiple( [ { event1 => \%params }, { event2 => \%params }, ... ] )

This method allows you to send a batch of events in a single HTTP request. It
is much more efficient than calling C<send()> several times.

Like C<send()>, it returns true if the request reached GA4 servers, and
false otherwise.

=head1 TROUBLESHOOTING

Google Analytics offers a validation server for your hits,
without risk of damaging your production analytics data. To access it, simply
set the 'C<debug>' flag to true when creating the object:

    my $ga = Net::Google::Analytics::MeasurementProtocol->new(
        api_secret     => '1234',
        measurement_id => '4321',
        debug          => 1,
    );

Now, calls to C<send()> and C<send_multiple()> will make the request to
Google's validation servers and return a hash reference containing response
information, which should indicate whether your request is valid or not and,
if not, why it wasn't accepted. So you can do something like this:

    # assuming the 'debug' flag is on:
    my $res = $ga->send( 'join_group' => { group_id => 'knitters#666' } );

    use DDP; p $res;

B<Make sure you disable "debug" before going live. Debug requests are sent to a different route and do not show up in your Google Analytics!>

Finally, if you have not passed a valid C<client_id> to the constructor, you should try it.
You can get a real one by adding the following JS snippet to your website's footer
(or anywhere AFTER loading Google Analytics (GA4) scripts either inline or via tools like
Google Tag Manager), then visiting it and inspecting the console log in your browser:

    <script>
      if(typeof gtag != 'function'){
        window.gtag = function() { dataLayer.push(arguments); }
      }
      gtag('get', 'YOUR_MEASUREMENT_ID_HERE', 'client_id', (client_id) => {
        console.log("client_id is " + client_id)
      });
    </script>

If even after all that your events are still not showing, please refer to L<Google's Troubleshoot Page|https://developers.google.com/analytics/devguides/collection/protocol/ga4/troubleshooting?client_type=gtag> for the Measuremnt Protocol.


=head1 KNOWN ISSUES

Right now it is not possible to send L<User Properties|https://developers.google.com/analytics/devguides/collection/protocol/ga4/user-properties?client_type=gtag>. Patches welcome!

This module also does not validate your input. Patches welcome!

=head1 SEE ALSO

L<Measurement Protocol for Google Analytics 4 (GA4)|https://developers.google.com/analytics/devguides/collection/protocol/ga4>

L<Measurement Protocol Reference|https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference?client_type=gtag>

L<GA4 Measurement Protocol - Validating Events|https://developers.google.com/analytics/devguides/collection/protocol/ga4/validating-events?client_type=gtag>

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2023 Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

Google and Google Analytics are trademarks of Google LLC.

This software is not endorsed by or affiliated with Google in any way.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
