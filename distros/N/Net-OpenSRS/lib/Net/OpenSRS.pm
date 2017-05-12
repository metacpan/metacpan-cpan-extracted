=head1 NAME

Net::OpenSRS - Domain registration via the Tucows OpenSRS HTTPS XML API

=head1 Description

This is a wrapper interface to the DNS portions of the Tucows OpenSRS
HTTPS XML API.

The client library distributed by OpenSRS can be difficult to integrate
into a custom environment, and their web interface becomes quickly
tedious with heavy usage. This is a clean and relatively quick library
to perform the most common API methods described in the OpenSRS API
documentation.

=head1 Examples

 use Net::OpenSRS;

 my $key = 'Your_API_Key_From_The_Reseller_Interface';
 my $srs = Net::OpenSRS->new();

 $srs->environment('live');
 $srs->set_key( $key );

 $srs->set_manage_auth( 'manage_username', 'manage_password' );

 my $cookie = $srs->get_cookie( 'spime.net' );
 if ($cookie) {
     print "Cookie:  $cookie\n";
 } else {
     print $srs->last_response() . "\n";
 }

 # do a batch of domain locks
 $srs->bulk_lock([ 'example.com', 'example.net', ... ]);

 # renew a domain
 my $result = $srs->renew_domain( 'example.com' );
 ...

=head1 Notes

=head2 Prerequisites

This module requires some setup in the OpenSRS reseller environment
before it will work correctly.

=over 4

=item Reseller account

You need to have an OpenSRS account, of course.  If you aren't an
OpenSRS reseller, this module will be of limited use to you. :)

=item Script API network access

The machine(s) using this module need to have their public IP addresses
added to your 'Script API allow' list in the OpenSRS web interface.
(You'll only need to do this once, assuming your IP doesn't change.)

=item API key generation

You'll need to pregenerate your API keys - also in the the OpenSRS web
interface.  These keys are used for all reseller API authentication.

=back

=head2 Assumptions

OpenSRS allows for a variety of ways to organize your domains.  Because
of this, writing a 'one size fits all' module is rather difficult.
Instead, we make a few assumptions regarding the way people use their
OpenSRS reseller accounts.

**** These assumptions will ultimately determine if this module is right for
you!  Please read them carefully! ****

=over 4

=item Management 'master' account.

We assume that all domains are under one global management owner
account.  If customers want access to the management interface, we're
operating under the idea that you create subaccounts for them -
retainting the master account information for your own use.  (If you
aren't doing this, it really makes things easier for you in the long
run.)

For example, 'spime.net' is my master management account.  Before doing
any register_domain() calls, I call master_domain('spime.net') - then
any transfers or registrations from that point forward are linked to
'spime.net'.  If a customer wants access to the SRS web management
interface, I can then just create a subaccount for just their domain,
so I retain absolute control -- in the event a customer forgets their
password, I'm covered.

=item Usernames

We assume that your management username 'master' account is identical to
your reseller username, and just the passwords differ.

=item Default registration info

We assume you've properly set up default technical contact information,
including your default nameservers, in the OpenSRS reseller web
interface.

=item Return codes

Unless otherwise noted, all methods return true on success, false on
failure, and undefined on caller error.

=back

=head2 Default environment

This library defaults to the TEST environment. (horizon.)  Many API
methods don't work in the test environment (SET COOKIE being the most
notable example, as any API method relying on a cookie doesn't work
either.)  Neither does batch processing.  Most everything else should be
ok.  ( See environment() )

=head2 The '$c' variable

Many methods require customer information.  I leave the method of
fetching this information entirely to you.  All examples below that show
a $c variable expect a hashref (or object) that contain these keys:

    my $c = {
        firstname => 'John',
        lastname  => 'Doe',
        city      => 'Portland',
        state     => 'Oregon',
        country   => 'US',
        address   => '555 Someplace Street',
        email     => 'john@example.com',
        phone     => '503-555-1212',
        company   => 'n/a'
    };

=cut

package Net::OpenSRS;

use strict;
use warnings;
use LWP::UserAgent;
use XML::Simple;
use Digest::MD5;
use Date::Calc qw/ Add_Delta_Days Today This_Year /;

our $VERSION = '0.06';
my $rv;
*hash = \&Digest::MD5::md5_hex;

#----------------------------------------------------------------------
# utility methods
#----------------------------------------------------------------------

=head1 Utility methods

=over 4

=item new()

 my $srs = Net::OpenSRS->new();

Create a new Net::OpenSRS object.  There are no options for this
method.

=cut

sub new
{
    my ($class, %opts) = @_;
    my $self = {};
    bless $self, $class;

    $self->{config} = {
        use_test_env  => 1,
        debug         => 0,
        master_domain => undef,

        bulkhost => 'https://batch.opensrs.net:55443',

        # reseller auth keys, as generated via the reseller website.
        live => {
            key  => undef,
            host => 'https://rr-n1-tor.opensrs.net:55443',
        },
        test => {
            key  => undef,
            host => 'https://horizon.opensrs.net:55443',
        }
    };

    return $self;
}

sub debug
{
    my $self = shift;
    return unless $self->debug_level;
    print STDERR shift() . "\n";
}

=item debug_level()

Setting the debug level will print various pieces of information to
STDERR when connecting to OpenSRS.  Use this if something isn't working
the way you think it should be.

=item 0

Disable debugging.

=item 1

Print current environment, host, and HTTP response.

=item 2

Add XML request and response to output.

=item 3

Add SSL debugging to output.

Debugging is off by default.  When called without an argument, returns
the current debug level.

=cut

sub debug_level
{
    my ($self, $level) = @_;
    return $self->{config}->{debug} unless $level;
    $self->{config}->{debug} = $level;
    return;
}

=item last_response()

All Net::OpenSRS methods set the last OpenSRS API reply in a temporary
variable.  You can view the contents of this variable using the
last_response() method.

Note that it is reset on each method call.

Returns the last OpenSRS return code and result string, or if passed any
true value, instead returns the full XML (parsed into a hashref) of the
last OpenSRS return. (perfect for Data::Dumper)

Examples:
   200: Command Successful
   400: Domain example.com does not exist with OpenSRS

=cut

sub last_response
{
    my ($self, $obj) = @_;
    return $obj ? $rv : $self->{last_response} || '';
}

=item set_manage_auth()

 $srs->set_manage_auth( $username, $password );

Set the owner management username and password.  This is used to fetch
cookies, and perform any API methods that require the management cookie.
For specifics on this, see the OpenSRS API documentation.

=cut

sub set_manage_auth
{
    my ($self, $user, $pass) = @_;
    return undef unless $user && $pass;
    $self->{config}->{username} = $user;
    $self->{config}->{password} = $pass;
    return 1;
}

=item set_key()

Tell the OpenSRS object what secret key to use for authentication.
You can generate a new secret key by using the OpenSRS reseller web
interface.  This key is required to perform any API functions.

set_key() is affected by the current environment().  Calling the
set_key() method while in the test environment only sets the key for the
test environment - likewise for the live environment.  To set a key for
the live environment, you need to call environment('live') B<first>.

=cut

sub set_key
{
    my ($self, $key) = @_;
    return undef unless $key;
    $self->{config}->{ $self->environment }->{key} = $key;
    return 1;
}

=item environment()

 my $env = $srs->environment;
 $srs->environment('live');

Without an argument, returns a string - either 'test', or 'live',
depending on the environment the object is currently using.

The test environment is the default.

If passed an argument (either 'test' or 'live') - switches into the
desired environment.  You will need to set_key() if you were previously
using a different environment, or if you hadn't set_key() yet.

=cut

sub environment
{
    my ($self, $env) = @_;
    return ($self->{config}->{use_test_env} ? 'test' : 'live')
        unless $env && $env =~ /(test|live)/i;
    $self->{config}->{use_test_env} = 
        $1 eq 'test' ? 1 : 0;
    return;
}

=item master_domain()

 my $master = $srs->master_domain;
 $srs->master_domain('spime.net');

Without an argument, returns the currently set 'master domain' account.
Otherwise, it sets the master domain.

New transfers and registrations are linked under this domain, for
centralized management.  See the 'Assumptions' section, above.

=cut

sub master_domain
{
    my ($self, $domain) = @_;
    return $self->{config}->{master_domain} unless $domain;
    $self->{config}->{master_domain} = $domain;
    return;
}

# set last status messages/codes in $self,
# for the benefit of the caller.
sub _set_response
{
    my $self = shift;
    $rv->{response_text} =~ s/Error: //;
    $self->{last_response} = $rv->{response_code} . ": " . $rv->{response_text};
    return;
}

#----------------------------------------------------------------------
# SRS API methods
#----------------------------------------------------------------------

=back

=head1 OpenSRS API methods

=over 4

=item bulk_lock() / bulk_unlock()

Locks or unlocks up to 1000 domains at a time.

 my $result = $srs->bulk_lock([ 'example.com', 'example.net' ]);

Returns remote bulk queue id on successful batch submission.

=cut

sub bulk_lock
{
    my $self = shift;
    return $self->_bulk_action( 'lock', @_ );
}

sub bulk_unlock
{
    my $self = shift;
    return $self->_bulk_action( 'unlock', @_ );
}

sub _bulk_action
{
    my ( $self, $toggle, $domains ) = @_;
    return undef unless $toggle =~ /lock|unlock/i && 
                        ref $domains;
    return undef if scalar @$domains >= 1000;

    $rv = $self->make_request(
        {
            batch   => 1,
            action  => 'submit',
            object  => 'bulk_change',
            attributes => {
                change_type => 'domain_lock',
                change_items => $domains,
                op_type => lc $toggle,
            }
        }
    );
    return undef unless $rv;

    $self->_set_response;
    return $rv->{is_success} ? $rv->{bulk_change_req_id} : 0;
}

=item check_queued_request()

 my $result = $srs->check_queued_request( $queue_id );

Requires queue id - returned from batch methods such as bulk_lock().
Always returns hashref of queue command on success.  
Check $srs->last_response() for status progress.

=cut

sub check_queued_request
{
    my ( $self, $id ) = @_;
    return undef unless $id;

    $rv = $self->make_request(
        {
            action  => 'query_queued_request',
            object  => 'domain',
            attributes => {
                request_id => $id,
            }
        }
    );
    return undef unless $rv;

    $self->_set_response;
    return $rv->{attributes}->{request_data};
}

=item check_transfer()

 my $result = $srs->check_transfer( 'example.com' );

Checks the status of a transfer in progress.  Returns hashref of
'contact_email', 'status', and 'last_update_time' for a given domain
transfer.  The 'status' key is always one of the following:

        pending_owner  (waiting on owner confirmation)
        pending_admin  (waiting on opensrs staff confirmation)
        pending_registry  (waiting on register to complete)
        completed  (transfer done)
        cancelled  (reseller cancelled transfer in progress)
        undefined  (no transfer in progress)

If the domain in question has no transfer in progress - instead checks
to see if the domain is capable of transfer.  Returns hashref of
'transferrable' (boolean) and 'reason' (string).

=cut

sub check_transfer
{
    my ( $self, $domain ) = @_;
    return undef unless $domain;

    $rv = $self->make_request(
        {
            action     => 'check_transfer',
            object     => 'domain',
            attributes => {
                domain              => $domain,
                get_request_address => 1,
            }
        }
    );
    return undef unless $rv;

    $self->_set_response;
    if ( $rv->{attributes}->{status} ) {
        return {
            status           => $rv->{attributes}->{status},
            last_update_time => $rv->{attributes}->{unixtime},
            contact_email    => $rv->{attributes}->{request_address}
        };
    }
    else {
        return $rv->{attributes}; #(transferrable bool and reason)
    }
}

=item get_cookie()

OpenSRS management APIs require a cookie to be generated, and sent along
with the API request.

 $cookie = $srs->get_cookie( 'example.com ');
 ($cookie, $expiration_date) = $srs->get_cookie( 'example.com ');

Make sure you've set_manage_auth() before attempting any cookie required
APIs.

Returns cookie on success, undefined on error.  (Check error with
last_response())

In array context, returns cookie and expiration date of the domain.

=cut

sub get_cookie
{
    my ($self, $domain) = @_;
    return undef unless $domain;
    $rv = $self->make_request(
        {
            action     => 'set',
            object     => 'cookie',
            attributes => {
                reg_username => $self->{config}->{username},
                reg_password => $self->{config}->{password},
                domain => $domain
            }
        }
    );
    return undef unless $rv;

    $self->_set_response;
    if ($rv->{is_success}) {
        return
          wantarray
          ? ( $rv->{attributes}->{cookie}, $rv->{attributes}->{expiredate} )
          : $rv->{attributes}->{cookie};
    }
    return undef;
}

=item get_expiring_domains()

 my $results = $srs->get_expiring_domains( 60 );

 Fetch and return OpenSRS hashref of expiring domains, within
 the specified timeperiod.  (In days.)

 Time period defaults to 30 days.

=cut

sub get_expiring_domains
{
    my ($self, $timeframe) = @_;
    $timeframe ||= 30;

    my $today   = join '-', map { sprintf( "%02d", $_ ) } Date::Calc::Today();
    my $expdate = join '-', map { sprintf( "%02d", $_ ) }
      Date::Calc::Add_Delta_Days( ( split '-', $today ), $timeframe );

    $rv = $self->make_request(
        {
            action     => 'get_domains_by_expiredate',
            object     => 'domain',
            attributes => {
                limit    => 1000,
                exp_from => $today,
                exp_to   => $expdate,
            }
        }
    );
    return undef unless $rv;

    $self->_set_response;
    return $rv->{attributes}->{exp_domains} if $rv->{is_success};
    return undef;
}

=item is_available()

Hey OpenSRS! Is this domain registered, or is it available?

 my $result = $srs->is_available( 'example.com ');

Returns true if the domain is available, false if it is already
registered.

=cut

sub is_available
{
    my ($self, $domain) = @_;
    return undef unless $domain;
    $rv = $self->make_request(
        {
            action     => 'lookup',
            object     => 'domain',
            attributes => {
                domain => $domain
            }
        }
    );
    return undef unless $rv;
    $self->_set_response;
    return undef unless $rv->{is_success};
    return $rv->{response_code} == 210 ? 1 : 0;
}

=item register_domain()

 my $result = $srs->register_domain( 'example.com', $c );

Register a new domain.  Default nameserver and tech info used from
OpenSRS settings.

=cut

sub register_domain
{
    my ($self, $domain, $c, $transfer) = @_;
    return undef unless $domain;

    # sanity checks
    unless ($self->{config}->{username}) {
        $self->debug("Management auth not set.");
        return undef;
    }
    unless (ref $c) {
        $self->debug("2nd arg must be a reference to customer info.");
        return undef;
    }

    my $epp_phone = $c->{phone};
    $epp_phone =~ s/[\.\-]//g;
    $epp_phone = '+1.' . $epp_phone;

    # blah, this sucks.
    # it would be really nice if OpenSRS figured out the country -> code
    # conversion on their end of things.
    my %country_codes = (
        'Afghanistan'                            => 'AF',
        'Albania'                                => 'AL',
        'Algeria'                                => 'DZ',
        'American Samoa'                         => 'AS',
        'Andorra'                                => 'AD',
        'Angola'                                 => 'AO',
        'Anguilla'                               => 'AI',
        'Antarctica'                             => 'AQ',
        'Antigua And Barbuda'                    => 'AG',
        'Argentina'                              => 'AR',
        'Armenia'                                => 'AM',
        'Aruba'                                  => 'AW',
        'Australia'                              => 'AU',
        'Austria'                                => 'AT',
        'Azerbaijan'                             => 'AZ',
        'Bahamas'                                => 'BS',
        'Bahrain'                                => 'BH',
        'Bangladesh'                             => 'BD',
        'Barbados'                               => 'BB',
        'Belarus'                                => 'BY',
        'Belgium'                                => 'BE',
        'Belize'                                 => 'BZ',
        'Benin'                                  => 'BJ',
        'Bermuda'                                => 'BM',
        'Bhutan'                                 => 'BT',
        'Bolivia'                                => 'BO',
        'Bosnia Hercegovina'                     => 'BA',
        'Botswana'                               => 'BW',
        'Bouvet Island'                          => 'BV',
        'Brazil'                                 => 'BR',
        'British Indian Ocean Territory'         => 'IO',
        'Brunei Darussalam'                      => 'BN',
        'Bulgaria'                               => 'BG',
        'Burkina Faso'                           => 'BF',
        'Burundi'                                => 'BI',
        'Cambodia'                               => 'KH',
        'Cameroon'                               => 'CM',
        'Canada'                                 => 'CA',
        'Cape Verde'                             => 'CV',
        'Cayman Islands'                         => 'KY',
        'Central African Republic'               => 'CF',
        'Chad'                                   => 'TD',
        'Chile'                                  => 'CL',
        'China'                                  => 'CN',
        'Christmas Island'                       => 'CX',
        'Cocos (Keeling) Islands'                => 'CC',
        'Colombia'                               => 'CO',
        'Comoros'                                => 'KM',
        'Congo'                                  => 'CG',
        'Congo The Democratic Republic Of'       => 'CD',
        'Cook Islands'                           => 'CK',
        'Costa Rica'                             => 'CR',
        'Cote D\'Ivoire'                         => 'CI',
        'Croatia'                                => 'HR',
        'Cuba'                                   => 'CU',
        'Cyprus'                                 => 'CY',
        'Czech Republic'                         => 'CZ',
        'Denmark'                                => 'DK',
        'Djibouti'                               => 'DJ',
        'Dominica'                               => 'DM',
        'Dominican Republic'                     => 'DO',
        'Ecuador'                                => 'EC',
        'Egypt'                                  => 'EG',
        'El Salvador'                            => 'SV',
        'Equatorial Guinea'                      => 'GQ',
        'Eritrea'                                => 'ER',
        'Estonia'                                => 'EE',
        'Ethiopia'                               => 'ET',
        'Falkland Islands (Malvinas)'            => 'FK',
        'Faroe Islands'                          => 'FO',
        'Fiji'                                   => 'FJ',
        'Finland'                                => 'FI',
        'France'                                 => 'FR',
        'French Guiana'                          => 'GF',
        'French Polynesia'                       => 'PF',
        'French Southern Territories'            => 'TF',
        'Gabon'                                  => 'GA',
        'Gambia'                                 => 'GM',
        'Georgia'                                => 'GE',
        'Germany'                                => 'DE',
        'Ghana'                                  => 'GH',
        'Gibraltar'                              => 'GI',
        'Greece'                                 => 'GR',
        'Greenland'                              => 'GL',
        'Grenada'                                => 'GD',
        'Guadeloupe'                             => 'GP',
        'Guam'                                   => 'GU',
        'Guatemela'                              => 'GT',
        'Guinea'                                 => 'GN',
        'Guinea-Bissau'                          => 'GW',
        'Guyana'                                 => 'GY',
        'Haiti'                                  => 'HT',
        'Heard and McDonald Islands'             => 'HM',
        'Honduras'                               => 'HN',
        'Hong Kong'                              => 'HK',
        'Hungary'                                => 'HU',
        'Iceland'                                => 'IS',
        'India'                                  => 'IN',
        'Indonesia'                              => 'ID',
        'Iran (Islamic Republic Of)'             => 'IR',
        'Iraq'                                   => 'IQ',
        'Ireland'                                => 'IE',
        'Israel'                                 => 'IL',
        'Italy'                                  => 'IT',
        'Jamaica'                                => 'JM',
        'Japan'                                  => 'JP',
        'Jordan'                                 => 'JO',
        'Kazakhstan'                             => 'KZ',
        'Kenya'                                  => 'KE',
        'Kiribati'                               => 'KI',
        'Korea, Democratic People\'s Republic Of' => 'KP',
        'Korea, Republic Of'                     => 'KR',
        'Kuwait'                                 => 'KW',
        'Kyrgyzstan'                             => 'KG',
        'Lao People\'s Democratic Republic'      => 'LA',
        'Latvia'                                 => 'LV',
        'Lebanon'                                => 'LB',
        'Lesotho'                                => 'LS',
        'Liberia'                                => 'LR',
        'Libyan Arab Jamahiriya'                 => 'LY',
        'Liechtenstein'                          => 'LI',
        'Lithuania'                              => 'LT',
        'Luxembourg'                             => 'LU',
        'Macau'                                  => 'MO',
        'Macedonia'                              => 'MK',
        'Madagascar'                             => 'MG',
        'Malawi'                                 => 'MW',
        'Malaysia'                               => 'MY',
        'Maldives'                               => 'MV',
        'Mali'                                   => 'ML',
        'Malta'                                  => 'MT',
        'Marshall Islands'                       => 'MH',
        'Martinique'                             => 'MQ',
        'Mauritania'                             => 'MR',
        'Mauritius'                              => 'MU',
        'Mayotte'                                => 'YT',
        'Mexico'                                 => 'MX',
        'Micronesia, Federated States Of'        => 'FM',
        'Moldova, Republic Of'                   => 'MD',
        'Monaco'                                 => 'MC',
        'Mongolia'                               => 'MN',
        'Montserrat'                             => 'MS',
        'Morocco'                                => 'MA',
        'Mozambique'                             => 'MZ',
        'Myanmar'                                => 'MM',
        'Namibia'                                => 'NA',
        'Nauru'                                  => 'NR',
        'Nepal'                                  => 'NP',
        'Netherlands'                            => 'NL',
        'Netherlands Antilles'                   => 'AN',
        'New Caledonia'                          => 'NC',
        'New Zealand'                            => 'NZ',
        'Nicaragua'                              => 'NI',
        'Niger'                                  => 'NE',
        'Nigeria'                                => 'NG',
        'Niue'                                   => 'NU',
        'Norfolk Island'                         => 'NF',
        'Northern Mariana Islands'               => 'MP',
        'Norway'                                 => 'NO',
        'Oman'                                   => 'OM',
        'Pakistan'                               => 'PK',
        'Palau'                                  => 'PW',
        'Palestine'                              => 'PS',
        'Panama'                                 => 'PA',
        'Papua New Guinea'                       => 'PG',
        'Paraguay'                               => 'PY',
        'Peru'                                   => 'PE',
        'Philippines'                            => 'PH',
        'Pitcairn'                               => 'PN',
        'Poland'                                 => 'PL',
        'Portugal'                               => 'PT',
        'Puerto Rico'                            => 'PR',
        'Qatar'                                  => 'QA',
        'Reunion'                                => 'RE',
        'Romania'                                => 'RO',
        'Russian Federation'                     => 'RU',
        'Rwanda'                                 => 'RW',
        'Saint Helena'                           => 'SH',
        'Saint Kitts And Nevis'                  => 'KN',
        'Saint Lucia'                            => 'LC',
        'Saint Pierre and Miquelon'              => 'PM',
        'Saint Vincent and The Grenadines'       => 'VC',
        'Samoa'                                  => 'WS',
        'San Marino'                             => 'SM',
        'Sao Tome and Principe'                  => 'ST',
        'Saudi Arabia'                           => 'SA',
        'Senegal'                                => 'SN',
        'Serbia and Montenegro'                  => 'CS',
        'Seychelles'                             => 'SC',
        'Sierra Leone'                           => 'SL',
        'Singapore'                              => 'SG',
        'Slovakia'                               => 'SK',
        'Slovenia'                               => 'SI',
        'Solomon Islands'                        => 'SB',
        'Somalia'                                => 'SO',
        'South Africa'                           => 'ZA',
        'South Georgia and The Sandwich Islands' => 'GS',
        'Spain'                                  => 'ES',
        'Sri Lanka'                              => 'LK',
        'Sudan'                                  => 'SD',
        'Suriname'                               => 'SR',
        'Svalbard and Jan Mayen Islands'         => 'SJ',
        'Swaziland'                              => 'SZ',
        'Sweden'                                 => 'SE',
        'Switzerland'                            => 'CH',
        'Syrian Arab Republic'                   => 'SY',
        'Taiwan'                                 => 'TW',
        'Tajikista'                              => 'TJ',
        'Tanzania, United Republic Of'           => 'TZ',
        'Thailand'                               => 'TH',
        'Timor-Leste'                            => 'TL',
        'Togo'                                   => 'TG',
        'Tokelau'                                => 'TK',
        'Tonga'                                  => 'TO',
        'Trinidad and Tobago'                    => 'TT',
        'Tunisia'                                => 'TN',
        'Turkey'                                 => 'TR',
        'Turkmenistan'                           => 'TM',
        'Turks and Caicos Islands'               => 'TC',
        'Tuvalu'                                 => 'TV',
        'Uganda'                                 => 'UG',
        'Ukraine'                                => 'UA',
        'United Arab Emirates'                   => 'AE',
        'United Kingdom (GB)'                    => 'GB',
        'United Kingdom (UK)'                    => 'UK',
        'United States'                          => 'US',
        'United States Minor Outlying Islands'   => 'UM',
        'Uruguay'                                => 'UY',
        'Uzbekistan'                             => 'UZ',
        'Vanuatu'                                => 'VU',
        'Vatican City State'                     => 'VA',
        'Venezuela'                              => 'VE',
        'Vietnam'                                => 'VN',
        'Virgin Islands (British)'               => 'VG',
        'Virgin Islands (U.S.)'                  => 'VI',
        'Wallis and Futuna Islands'              => 'WF',
        'Western Sahara'                         => 'EH',
        'Yemen Republic of'                      => 'YE',
        'Zambia'                                 => 'ZM',
        'Zimbabwe'                               => 'ZW'
    );  # end suckage

    # attempt countryname translation if needed
    if ( $c->{country} !~ m/^[A-Z]{2,3}$/ ) {
    	$c->{country} = $country_codes{$c->{country}};

        unless ( defined( $c->{country} ) ) {
            $self->debug("Invalid country.");
            return undef;
        }
    }

    # build contact hashref from customer info.
    my $contact_info = {
        first_name  => $c->{firstname},
        last_name   => $c->{lastname},
        city        => $c->{city},
        state       => $c->{state},
        country     => $c->{country},
        address1    => $c->{address},
        postal_code => $c->{zip},
        email       => $c->{email},
        phone       => $epp_phone,
        org_name    => $c->{company} || 'n/a',
    };

    $rv = $self->make_request(
        {
            action     => 'sw_register',
            object     => 'domain',
            attributes => {
                domain              => $domain,
                custom_nameservers  => 0,
                custom_tech_contact => 0,
                auto_renew          => 0,
                period              => 1,
                f_lock_domain       => 1,
                contact_set         => {
                    admin   => $contact_info,
                    billing => $contact_info,
                    owner   => $contact_info
                },
                reg_username => $self->{config}->{username},
                reg_password => $self->{config}->{password},
                reg_type   => $transfer ? 'transfer' : 'new',
                reg_domain => $self->{config}->{master_domain}, # link domain to the 'master' account
            }
        }
    );
    $self->_set_response;
    return $rv->{is_success};
}

=item renew_domain()

 my $result = $srs->renew_domain( 'example.com', 1 );

Renew a domain for a period of time in years. 1 year is the default.

=cut

sub renew_domain
{
    my ($self, $domain, $years) = @_;
    return undef unless $domain;
    $years ||= 1;

    # sanity checks
    unless ($self->{config}->{username}) {
        $self->debug("Management auth not set.");
        return undef;
    }

    # get current expiration year (why do they need this, again?)
    my (undef, $expiration) = $self->get_cookie( $domain );
    $expiration = $1 if $expiration =~ /^(\d{4})-/;
    $expiration ||= Date::Calc::This_Year();
    
    $rv = $self->make_request(
        {
            action     => 'renew',
            object     => 'domain',
            attributes => {
                domain                => $domain,
                auto_renew            => 0,
                handle                => 'process',
                period                => $years,
                currentexpirationyear => $expiration,
            }
        }
    );
    $self->_set_response;
    return $rv->{is_success};
}

=item revoke_domain()

Revoke a previously registered domain.  This only works if the domain is
still within the grace period as defined by the registrar.
Requires you to have called set_manage_auth() B<first>.

 my $result = $srs->revoke_domain( 'example.com' );

Returns true if the revoke is successful, false otherwise.
Returns undefined on error.

=cut

sub revoke_domain
{
    my ($self, $domain) = @_;
    return undef unless $domain;
    unless ($self->{config}->{username}) {
        $self->debug("Management auth not set.");
        return undef;
    }
    $rv = $self->make_request(
        {
            action     => 'revoke',
            object     => 'domain',
            attributes => {
                reseller => $self->{config}->{username},
                domain => $domain,
            }
        }
    );
    $self->_set_response;
    return $rv->{is_success};
}

=item transfer_domain()

 my $result = $srs->transfer_domain( 'example.com', $c );

Transfer a domain under your control.
Returns true on success, false on failure, and undefined on caller error.

=cut

sub transfer_domain
{
    my $self = shift;
    return $self->register_domain( @_, 1 );
}

=item make_request()

This method is the real workhorse of this module.  If any OpenSRS API
isn't explicity implemented in this module as a method call (such as
get_cookie(), bulk_lock(), etc), you can use make_request() to build and send
the API yourself.

Examples:

 my $result = $srs->make_request(
     {
         batch   => 1,
         action  => 'submit',
         object  => 'bulk_change',
         attributes => {
             change_type => 'domain_lock',
             change_items => [ 'example.com', 'example.net' ],
             op_type => 'lock',
         }
     }
 );

 my $result = $srs->make_request(
     {
         action     => 'lookup',
         object     => 'domain',
         attributes => {
             domain => 'example.com'
         }
     }
 );

Returns a hashref containing parsed XML results from OpenSRS.

Example return:

 {
     'protocol' => 'XCP',
     'object' => 'DOMAIN',
     'response_text' => 'Domain taken',
     'action' => 'REPLY',
     'response_code' => '211',
     'attributes' => {
         'status' => 'taken',
         'match' => {}
     },
     'is_success' => '1'
 }

=cut

# build opensrs xml protocol string.  submit.
# convert xml response to data structure, and return.
sub make_request
{
    my ($self, $data) = @_;
    return undef unless ref $data;

    $self->debug("Using " . $self->environment . " environment.");

    my $key  = $self->{config}->{ $self->environment }->{key};
    my $host = $self->{config}->{ $self->environment }->{host};
    $ENV{HTTPS_DEBUG} = 1 if $self->debug_level > 2;

    unless ($key) {
        $self->debug("Authentication key not set.");
        return undef;
    }

    my $action = uc $data->{action};
    my $object = uc $data->{object};

    # build our XML request.
    # lets not bother with anything super fancy, 
    # everything but the item keys are always static anyway.
    my $xml;
    $xml = <<XML;
<?xml version='1.0' encoding="UTF-8" standalone="no" ?>
<!DOCTYPE OPS_envelope SYSTEM "ops.dtd">
<OPS_envelope>
<header><version>0.9</version></header>
<body>
<data_block>
<dt_assoc>
  <item key="protocol">XCP</item>
  <item key="action">$action</item>
  <item key="object">$object</item>
XML

    $xml .= "  <item key=\"cookie\">$data->{cookie}</item>\n" if $data->{cookie};

$xml .= <<XML;
  <item key="attributes">
    <dt_assoc>
XML

    foreach (sort keys %{ $data->{attributes} }) {
        my $val = $data->{attributes}->{$_};
        $xml .= $self->_format( $val, 4 );
    }
    $xml .= <<XML;
    </dt_assoc>
  </item>
</dt_assoc>
</data_block>
</body>
</OPS_envelope>
XML

    # whoof, ok.  got our request built.  lets ship it off.
    if ($self->debug_level > 1) {
        $self->debug("\nClient Request XML:\n" . '-' x 30);
        $self->debug($xml);
    }

    $host = $self->{config}->{bulkhost} if $data->{batch};
    $self->debug("Making request to $host...");
    my $ua = LWP::UserAgent->new( timeout => 20, agent => "Net::OpenSRS/$VERSION" );
    unless ($ua) {
        $self->debug("Unable to contact remote host.");
        return undef;
    }

    my $res = $ua->post( 
        $host,
        'Content-Type' => 'text/xml',
        'X-Username'   => $self->{config}->{username},
        'X-Signature'  => hash( hash( $xml, $key ), $key ),
        'Content'      => $xml
    );

    my $struct;
    if ( $res->is_success ) {
        $self->debug("HTTP result: " . $res->status_line);
        my $rslt = $res->content;
        # OpenSRS renew response triggers Expat parser error due to spaces in element name
        $rslt =~ s/registration expiration date/registration_expiration_date/g;

        eval { $struct = XML::Simple::XMLin(
                 $rslt,
                 'KeyAttr' => [ 'dt_assoc' ],
                 'GroupTags' => { 'dt_assoc' => 'item',  'dt_array' => 'item' },
               );
        };

        if ($self->debug_level > 1) {
            $self->debug("\nOpenSRS Response XML:\n" . '-' x 30);
            $self->debug($res->content);
            $self->debug('');
        }

        # get the struct looking just how we want it.
        # (de-nastify it.)
        (undef, $struct) = _denastify( $struct->{body}->{data_block} );
    }
    else {
        $self->debug("HTTP error: " . $res->status_line);
        return undef;
    }

    $rv = $struct;
    $self->_set_response;
    return $self->last_response(1);
}

# encode special characters

my %encode_hash = (
  '<' => '&lt;',
  '>' => '&gt;',
  "'" => '&apos;',
  '"' => '&quot;',
  '&' => '&amp;',
);

sub _encode
{
  my $arg = shift;
  return $arg unless ($arg =~/\<|\>|\'|\"|\&/);
  $arg =~ s/(\<|\>|\'|\"|\&)/$encode_hash{$1}/ge;
  $arg
}

# format perl structs into opensrs XML
sub _format
{
    my ($self, $val, $indent) = @_;
    my $xml;

    $indent ||= 6;
    my $sp = ' ' x $indent;

    if ( ref $val eq 'ARRAY' ) {
        my $c = 0;
        $xml .= "$sp<item key=\"$_\">\n";
        $xml .= "$sp  <dt_array>\n";
        foreach (map { _encode($_) } sort @$val) {
            $xml .= "$sp    <item key=\"$c\">$_</item>\n";
            $c++;
        }
        $xml .= "$sp  </dt_array>\n";
        $xml .= "$sp</item>\n";
    }

    elsif ( ref $val eq 'HASH' ) {
        $xml .= "$sp<item key=\"$_\">\n";
        $xml .= "$sp<dt_assoc>\n";
        foreach (sort keys %$val) {
            $xml .= $self->_format( $val->{$_} );
        }
        $xml .= "$sp</dt_assoc>\n";
        $xml .= "$sp</item>\n";
    }

    else {
        $val = _encode($val);
        $xml .= "$sp<item key=\"$_\">$val</item>\n";
    }

    return $xml;
}

sub _denastify {
    my ($arg) = ( shift );

    if ( 0 ) {
      eval { use Data::Dumper };
      warn $@ if $@;
      warn "_denastify\n". Dumper($arg) unless $@;
    }

    if ( ref($arg) eq 'HASH' ) {
        my $value;
        if ( exists( $arg->{content} ) ) {
            $value = $arg->{content};
        } elsif ( exists( $arg->{dt_array} ) ) {
            my $array = $arg->{dt_array};
            $array = [ $array ] unless ref($array) eq 'ARRAY';
            $value = [ map {
                               { map { _denastify($_) } @{ $_->{dt_assoc} } }
                           }
                       @$array
                     ];
        } elsif ( exists( $arg->{dt_assoc} ) ) {
            my $array = $arg->{dt_assoc};
            $array = [ $array ] unless ref($array) eq 'ARRAY';
            $value = { map { _denastify($_) } @$array };
        }
        return ( $arg->{key} => $value );
    }
    ();
}

=back

=head1 Author

Mahlon E. Smith I<mahlon@martini.nu> for Spime Solutions Group
I<(www.spime.net)>

=cut

1;
