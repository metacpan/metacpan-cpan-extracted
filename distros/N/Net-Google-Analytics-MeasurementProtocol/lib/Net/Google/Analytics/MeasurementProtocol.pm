package Net::Google::Analytics::MeasurementProtocol;
use strict;
use warnings;
use Carp ();

our $VERSION = 0.05;

sub new {
    my $class = shift;
    my %args = (@_ == 1 ? %{$_[0]} : @_ );

    Carp::croak 'tracking_id (tid) missing or invalid'
        unless $args{tid} && $args{tid} =~ /^(?:UA|MO|YT)-\d+-\d+$/;

    # If the 'aip' key exists, even if set to 0, the ip will be anonymized.
    # So we only push it to our args if user set it to 1.
    delete $args{aip} if exists $args{aip} && !$args{aip};

    # default settings:
    $args{ua}  ||= __PACKAGE__ . "/$VERSION";
    $args{cid} ||= _gen_uuid_v4();
    $args{v}   ||= 1;
    $args{cd}  ||= '/';
    $args{an}  ||= 'My App';
    $args{ds}  ||= 'app';

    my $ua_object = delete $args{ua_object} || _build_user_agent( $args{ua} );
    unless ( $ua_object->isa('Furl') || $ua_object->isa('LWP::UserAgent') ) {
        Carp::croak('ua_object must be of type Furl or LWP::UserAgent');
    }

    my $debug = delete $args{debug};
    return bless {
        args  => \%args,
        debug => $debug,
        ua    => $ua_object,
    }, $class;
}

sub send {
    my ($self, $hit_type, $args) = @_;

    return $self->_request( $self->_build_request_args( $hit_type, $args ) );
}

sub _build_request_args {
    my ($self, $hit_type, $args) = @_;

    my %args = (%{$self->{args}}, %$args, t => $hit_type);
    my %required = (
        pageview    => [qw(v tid cid cd an)],
        screenview  => [qw(v tid cid cd an)],
        event       => [qw(v tid cid cd an ec ea)],
        transaction => [qw(v tid cid cd an ti)],
        item        => [qw(v tid cid cd an ti in)],
        social      => [qw(v tid cid cd an sn sa st)],
        exception   => [qw(v tid cid cd an)],
        timing      => [qw(v tid cid cd an utc utv utt)],
    );
    Carp::croak("invalid hit type $hit_type") unless $required{$hit_type};

    foreach my $required ( @{$required{$hit_type}} ) {
        Carp::croak("argument '$required' is required for '$hit_type' hit type. See https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters#$required for more information")
            unless $args{$required};
    }
    Carp::croak('for "pageview" hit types you must set either "dl" or both "dh" and "dp"')
        if $hit_type eq 'pageview' && !($args{dl} || ($args{dh} && $args{dp}));
    return \%args;
}

sub _request {
    my ($self, $args) = @_;

    my $ua = $self->{ua};
    my $target = $self->{debug}
        ? 'https://www.google-analytics.com/debug/collect'
        : 'https://www.google-analytics.com/collect'
        ;

    # Compatibility layer for LWP::UserAgent
    my $res = $ua->post( $target, $ua->isa('Furl') ? undef : (), $args );

    return $self->{debug} ? $res : $res->is_success;
}

sub _build_user_agent {
    my ($ua) = @_;
    require Furl;
    return Furl->new( agent => $ua, timeout => 5 );
}

# UUID v4 (pseudo-random) generator based on UUID::Tiny
sub _gen_uuid_v4 {
    my $uuid = '';
    for ( 1 .. 4 ) {
        my $v1 = int(rand(65536)) % 65536;
        my $v2 = int(rand(65536)) % 65536;
        my $rand_32bit = ($v1 << 16) | $v2;
        $uuid .= pack 'I', $rand_32bit;
    }
    substr $uuid, 6, 1, chr( ord( substr( $uuid, 6, 1 ) ) & 0x0f | 0x40 );
    substr $uuid, 8, 1, chr( ord( substr( $uuid, 8, 1 ) ) & 0x3f | 0x80 );

    # uuid is created. Convert to string:
    return join '-',
           map { unpack 'H*', $_ }
           map { substr $uuid, 0, $_, '' }
           ( 4, 2, 2, 2, 6 );
}

1;
__END__

=head1 NAME

Net::Google::Analytics::MeasurementProtocol - send Google Analytics user interaction data from Perl

=for html
<a href="https://travis-ci.org/garu/Net-Google-Analytics-MeasurementProtocol"><img src="https://travis-ci.org/garu/Net-Google-Analytics-MeasurementProtocol.svg"></a>

=head1 SYNOPSIS

    use Net::Google::Analytics::MeasurementProtocol;

    my $ga = Net::Google::Analytics::MeasurementProtocol->new(
        tid => 'UA-XXXX-Y',
    );

    # Now, instead of this JavaScript:
    # ga('send', 'pageview', {
    #     'dt': 'my new title'
    # });

    # you can do this, in Perl:
    $ga->send( 'pageview', {
        dt => 'my new title',
        dl => 'http://www.example.com/some/page',
    });


=head1 DESCRIPTION

This is a Perl interface to L<Google Analytics Measurement Protocol|https://developers.google.com/analytics/devguides/collection/protocol/v1/>,
allowing developers to make HTTP requests to send raw user interaction data
directly to Google Analytics servers. It can be used to tie online to offline
behaviour, sending analytics data from both the web (via JavaScript) and
from the server (via this module).

=head1 CONSTRUCTOR

=head2 new( %options )

=head2 new( \%options )

    my $ga = Net::Google::Analytics::MeasurementProtocol->new(
        tid => 'UA-1234567-8',
        aip => 1,
        cid => $some_UUID_version4,
    );

Creates a new object with the provided information. There are many options
to customize behaviour.

=head3 Required parameters:

=over 4

=item * tid
String. This is the tracking ID / web property ID. You should have gotten
this from your Google Analytics account, and it looks like C<"UA-XXXX-Y">.
All collected data is associated by this ID.

=back

=head3 Parameters with default values

=over 4

=item * v (for "version")
Number string. B<Defaults to '1'>, which is the current version (March 2016).
This is the protocol version to use. According to Google, this will only
change when there are changes made that are not backwards compatible.

=item * aip (for "anonymize ip")
Boolean. B<Defaults to 1>. If set to true, the IP address of the sender
(your server) will be anonymized.

=item * cid (for "client id")
L<String with UUID version 4|http://www.ietf.org/rfc/rfc4122.txt>.
B<Defaults to a random UUID> created for this object (staying the same for
as long as the object lives). This anonymously identifies a particular user,
device, or browser instance. For the web, this is generally stored as a
first-party cookie with a two-year expiration. For mobile apps, this is
randomly generated for each particular instance of an application install.

B<< It is recommended that you set this to a single value and use that same value throughout your app >>.

=item * cd (for "screen name")
String. B<Defaults to "/">. The screen name of the 'screenview' hit.

=item * an (for "application name")
String. B<defaults to "My App">. Specifies the application name.

=item * ds (for "data source")
String. B<Defaults to "app">. Indicates the data source of the hit.

=item * ua (for "user agent")
String. Defaults to "Net::Google::Analytics::MeasurementProtocol/$VERSION".

=item * ua_object

Object.  Either a L<Furl> object, L<LWP::UserAgent> or something with inherits
from L<LWP::UserAgent>, like L<WWW::Mechanize>. Defaults to using L<Furl>.

=back

=head3 Other parameters

There are many, I<many> parameters available. Please check the official
L<Measurement Protocol Parameter Reference|https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters>.

=head1 METHODS

=head2 send( $type, \%params )

Arguments:

=over 4

=item * C<$type> - The hit type. Can be I<pageview>, I<screenview>, I<event>,
I<transaction>, I<item>, I<social>, I<exception> or I<timing>.

=item * C<\%params> - Hashref with L<any other options|/"Other parameters">
you want to send to Google Analytics.

=back

B<Returns:> true/false, whether the request was accepted by Google Analytics
servers or not. I<NOTE>: If you set the C<debug> flag, it will return the full
response object for inspection. See the L</DEBUGGING> section below for more
information.

=head1 DEBUGGING

According to L<Google Analytics' documentation|https://developers.google.com/analytics/devguides/collection/protocol/v1/reference>,
the Measurement Protocol will return a 2xx status code if the HTTP request
was received. The Measurement Protocol B<does not> return an error code
if the payload data was malformed, or if the data in the payload was
incorrect or was not processed by Google Analytics.

If you do not get a I<2xx> status code, your call to L<send|/send> will
return I<false>. If it does, you should B<NOT> retry the request.
Instead, you should stop and correct any errors in your HTTP request.

Fortunately, Google Analytics offers a validation server for your hits,
without risk of damaging your production analytics data. To access it, simply
set the 'C<debug>' flag to true when creating the object:

    my $ga = Net::Google::Analytics::MeasurementProtocol->new(
        tid   => 'UA-XXXX-Y',
        debug => 1,
    );

Now, calls to L<send|/send> will make the request to Google's validation
servers and return the entire response object, which should contain JSON
indicating whether your request is valid or not, and if not, why it wasn't
accepted. So you can do something like this:

    use Data::Printer;
    use JSON;

    # assuming the 'debug' flag is on:
    my $res = $ga->send( 'pageview', { dl => 'http://www.example.com' } );

    my $data = JSON::decode_json( $res->decoded_content );

    my $is_valid = $data->{hitParsingResult}[0]{valid};
    if (!$is_valid) {
        p $data;
    }

=head1 SEE ALSO

L<Google Analytics Measurement Protocol Parameter Reference|https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters>

L<Google Analytics Measurement Protocol Reference|https://developers.google.com/analytics/devguides/collection/protocol/v1/reference>

L<Google Analytics Measurement Protocol - Validating Hits|https://developers.google.com/analytics/devguides/collection/protocol/v1/validating-hits>

L<Measurement Protocol Developer Guide|https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide>


=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


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

