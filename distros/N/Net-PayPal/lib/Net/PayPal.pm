package Net::PayPal;

# $Id$

use 5.005;
use strict;
use JSON;
use LWP;
use Crypt::CBC;
use Carp ("croak");
use Cache::FileCache;

our $VERSION = '0.02';

our $ENDPOINT_SANDBOX = "https://api.sandbox.paypal.com";
our $ENDPOINT_LIVE    = "https://api.paypal.com";

my $live = 0;

sub live {
    my $class = shift;
    my ($value) = @_;
    return $live = $value;
}

sub endpoint {
    my $class = shift;

    if ( $live == 1 ) {
        return $ENDPOINT_LIVE;
    }
    return $ENDPOINT_SANDBOX;
}

sub new {
    my $class = shift;

    my %args = (
        client_id    => $_[0],
        secret       => $_[1],
        user_agent   => LWP::UserAgent->new,
        app_id       => undef,
        access_token => undef,
        @_
    );

    unless ( $args{client_id} && $args{secret} ) {
        croak " new() : client_id and secret are missing ";
    }

    #
    # checking if access_token is available from previous requests
    #
    my $cache = Cache::FileCache->new( { cache_root => File::Spec->tmpdir, namespace => 'NetPayPal' } );

    my $cipher = Crypt::CBC->new( -key => $args{"secret"}, -cipher => 'Blowfish' );

    if ( my $e_token = $cache->get( $args{"client_id"} ) ) {
        $args{access_token} = $cipher->decrypt($e_token);
    }

    else {

        # if access_token cannot be found in the cache we need to authenticate ourselves to get one
        my $ua = $args{user_agent};

        my $h = HTTP::Headers->new(
            Accept            => "application/json",
            'Accept-Language' => 'en_US'
        );

        $h->authorization_basic( $args{client_id}, $args{secret} );

        my $endpoint = $class->endpoint;

        my $req = HTTP::Request->new( "POST", $endpoint . '/v1/oauth2/token', $h );
        $req->content("grant_type=client_credentials");

        my $res = $ua->request($req);
        unless ( $res->is_success ) {
            croak "Authorization failed : " . $res->status_line . ', ' . $res->content;
        }

        my $res_hash = _json_decode( $res->content );

        $args{access_token} = $res_hash->{access_token};
        $args{app_id}       = $res_hash->{app_id};

        $cache->set( $args{"client_id"}, $cipher->encrypt( $args{access_token} ), $res_hash->{expires_in} - 5 );
    }
    return bless( \%args, $class );
}

my $json = JSON->new->allow_nonref;

sub _json_decode {
    my $text = shift;
    my $hashref;
    eval { $hashref = $json->decode($text); };

    if ( my $error = $@ ) {
        croak "_json_decode(): cannot decode $text: $error";
    }
    return $hashref;
}

sub _json_encode {
    my $hashref = shift;
    return $json->encode($hashref);
}

sub rest {
    my $self = shift;
    my ( $method, $path, $json, $dump_responce ) = @_;

    unless ( $path =~ /\/$/ ) {
        $path = $path . '/';
    }

    my $endpoint = $self->endpoint;
    $endpoint = sprintf( " % s%s", $endpoint, $path );
    my $a_token = $self->{access_token};
    my $req = HTTP::Request->new( $method, $endpoint, [ 'Content-Type', 'application/json', 'Authorization', "Bearer $a_token" ] );

    if ($json) {
        $req->content($json);
    }

    my $ua  = $self->{user_agent};
    my $res = $ua->request($req);

    if ($dump_responce) {
        require Data::Dumper;
        return Data::Dumper::Dumper($res);
    }

    unless ( $res->is_success ) {
        if ( my $content = $res->content ) {
            my $error = _json_decode( $res->content );
            $self->error( sprintf( "%s: %s. See: %s", $error->{name}, $error->{message}, $error->{information_link} ) );
            return undef;
        }
        $self->error( $res->status_line );
        return undef;
    }
    return _json_decode( $res->content );
}

sub cc_payment {
    my $self = shift;
    my ($data) = @_;

    foreach my $field (qw/cc_number cc_type cc_expire_month cc_expire_year/) {
        unless ( $data->{$field} ) {
            croak "payment(): $field is a required field";
        }
    }

    my %credit_card = (
        number       => $data->{cc_number},
        type         => $data->{cc_type},
        expire_month => $data->{cc_expire_month},
        expire_year  => $data->{cc_expire_year}
    );

    foreach my $field (qw/first_name last_name billing_address/) {
        if ( $data->{$field} ) {
            $credit_card{$field} = $data->{$field};
        }
    }

    my $request_hash = {
        intent => 'sale',
        payer  => {
            payment_method      => "credit_card",
            funding_instruments => [ { credit_card => \%credit_card } ]
        },
        transactions => [
            {
                amount => {
                    total    => $data->{amount},
                    currency => $data->{currency} || "USD"
                },
            }
        ]
    };

    if ( $data->{redirect_urls} ) {
        $request_hash->{redirect_urls} = $data->{redirect_urls};
    }

    return $self->rest( 'POST', "/v1/payments/payment", _json_encode($request_hash) );
}

sub stored_cc_payment {
    my $self = shift;
    my ($data) = @_;

    unless ( $data->{id} ) {
        croak "stored_cc_payment(): 'id' is missing";
    }

    my $request_hash = {
        intent => 'sale',
        payer  => {
            payment_method      => "credit_card",
            funding_instruments => [ { credit_card_token => { credit_card_id => $data->{id} } } ]
        },
        transactions => [
            {
                amount => {
                    total    => $data->{amount},
                    currency => $data->{currency} || "USD"
                },
            }
        ]
    };

    if ( $data->{redirect_urls} ) {
        $request_hash->{redirect_urls} = $data->{redirect_urls};
    }

    return $self->rest( 'POST', "/v1/payments/payment", _json_encode($request_hash) );
}

sub get_payment {
    my $self = shift;
    my ($id) = @_;

    unless ($id) {
        croak "get_payment(): Invalid Payment ID";
    }

    return $self->rest( "GET", "/v1/payments/payment/$id" );
}

sub get_payments {
    my $self = shift;

    return $self->rest( "GET", "/v1/payments/payment" );
}

sub store_cc {
    my $self = shift;
    my ($data) = @_;

    my %credit_card = (
        number       => $data->{number}       || $data->{cc_number},
        type         => $data->{type}         || $data->{cc_type},
        expire_month => $data->{expire_month} || $data->{cc_expire_month},
        expire_year  => $data->{expire_year}  || $data->{cc_expire_year}
    );

    if ( my $cvv2 = $data->{cvv2} || $data->{cc_cvv2} ) {
        $credit_card{cvv2} = $cvv2;
    }

    foreach my $field (qw/first_name last_name billing_address/) {
        if ( $data->{$field} ) {
            $credit_card{$field} = $data->{$field};
        }
    }
    return $self->rest( 'POST', "/v1/vault/credit-card", _json_encode( \%credit_card ) );
}

sub get_cc {
    my $self = shift;
    my ($id) = @_;
    return $self->rest( "GET", "/v1/vault/credit-card/$id" );
}

my $last_error;

sub error {
    my $self = shift;
    my ($new_message) = @_;

    unless ($new_message) {
        return $last_error;
    }

    $last_error = $new_message;
}

1;
__END__

=head1 NAME

Net::PayPal - Perl extension for PayPal's REST API server

=head1 SYNOPSIS

    use Net::PayPal;
    my $p = Net::PayPal->new($client_id, $client_secret);

    my $payment = $p->cc_payment({
        cc_number       => '4353185781082049',
        cc_type         => 'visa',
        cc_expire_month => 3,
        cc_expire_year  => 2018,
        amount          => 19.95,
    });

    unless ( $payment ) {
        die $p->error;
    }

    unless ( $payment->{state} eq "approved" ) {
        printf("Your payment was not approved");
    }


=head1 WARNING

Since as of this writing (March 10th, 2013) PayPal's REST api was still in B<BETA> state it's fair to consider Net::PayPal is an B<ALPHA> software, meaning any part
of this module may change in subsequent releases. In the meantime any suggestions and feedback and contributions are welcome.

Consult CHANGES file in the root folder of the distribution before upgrading

=head1 DESCRIPTION

Net::PayPal implements PayPal's REST API. Visit http://developer.paypal.com for further information.

To start using Net::PayPal the following actions must be completed to gain access to API endpoints:

=over 4

=item 1

Sign up for a developer account by visiting http://developer.paypal.com. It is free!

=item 2

Under "Applications" tab (after signing into developer.paypal.com) make note of C<secret> and C<client_id>. You will need these two identifiers
to interact with PayPal's API server

=item 3

Create Net::PayPal instance using C<secret> and C<client_id> identifiers.

=back

=head2 SUPPORTED APIs

As of this writing the following APIs are implemented. As PayPal's REST Api evolves this module will evolve together

=over 4

=item POST /v1/payments/payment

=item GET /v1/payments/payment/{payment_id}

=item POST /v1/vault/credit-card

=item GET /v1/vault/credit-card/{credit_card_id}

=back

See L<rest()> method for everything else

=head2 METHODS

Following methods are available

=head3 new($client_id, $secret);

Creates and returns an instance of Net::PayPal class. If it's the first time you call this method within 8 hour period it will attempt to authenticate
the instance by submitting your credentials to paypal's /v1/oauth/token API. The access token is then cached for 8 hour period in your system's temp folder.

C<access_token> is a very sensitive data. For this reason Net::PayPal encrypts this data using Blowfish algorithm, using your C<secret> as key. As long as
you can keep your C<secret> identifier in secret your access token is reasonably safe!

Caching is very useful. Without cahing each API call in separate processes must attempt to authenticate the API, thus slowing down each API call.
By making use of caching technique a separate token is stored for each client_id in the temp folder.

=head3 cc_payment(\%data)

Charges a credit card:

    my $payment = $p->cc_payment({
        cc_number       => '4353185781082049',
        cc_type         => 'visa',
        cc_expire_month => 3,
        cc_expire_year  => 2018,
        first_name      => 'Sherzod',
        last_name       => 'Ruzmetov',
        amount          => 19.95,
    }) or die $p->error;

You may choose to store C<id> payment attribute should you wish to lookup payment details in the future. The state of the payment is stored in
'state' attribute:

    unless ( $payment->{state} eq 'approved' ) {
        die "Your payment wasn't approved";
    }

On error returns undef. Last error message can be queried through error() class method.

=head3 stored_cc_payment(\%data)

The same as L<cc_payment()>, except using a credit card stored in vault

    my $payment = $p->cc_payment({
        id      => 'CARD-ADFA13413241241324'
        amount  => '19.95',
        currency=> 'USD'
    });

C<id> is the result of previously invoked L<store_cc()>.

On error returns undef. Last error message can be queried through error() class method.

=head3 get_payment( $id )

Returns previously processed payment information, given the payment ID.

    my $payment = $p->get_payment( 'PAY-9D023728F47376036KE5OTKY' );

On error returns undef. Last error message can be queried through error() class method.

=head3 get_payments()

Returns list of previously processed payments.

    my @payments = $p->get_payments;

On error returns undef. Last error message can be queried through error() class method.

=head3 store_cc(\%credit_card);

Stores a credit card profile in the vault:

    my $cc = $p->store_cc({
        cc_number       => '4353185781082049',
        cc_type         => 'visa',
        cc_expire_month => '3',
        cc_expire_year  => '201'8,
        cvv2            => '420',
        first_name      => 'Sherzod',
        last_name       => 'Ruzmetov'
    });


C<id> is probably the most important attribute of the response data. To make a payment using the stored CC see L<stored_cc_payment()> method.


=head3 get_cc( $id )

Retrieves stored CC information from the database. Usual, in real world applications there is rarely a need for this method. Since once can already
charge a credit card without retrieving it completely.

    my $cc = get_cc( $id );

On error returns undef. Last error message can be queried through error() class method.


=head3 rest($method, $path)

=head3 rest($method, $path, $json_or_hashref);

To make up for missing API methods and PayPal's future upgrades to its REST API I decided to provide this convenience method. Basically all other
methods of Net::PayPal rely on this method to make things happen. It takes care of all OAuth2 specific authentication that PayPal requires.

For example:

    my $r = $pp->cc_payment({
        cc_number   => '...',
        cc_type     => 'visa',
        cc_expire_month => '...',
        cc_expire_year  => '...',
        cvv2    => '...',
        amount  => '19.95',
        currency => 'USD'
    });

Is equivalent to:

    my $r = $pp->rest('POST', '/v1/payments/payment', {
        intent => 'sale',
        payer  => {
            payment_method      => "credit_card",
            funding_instruments => [{credit_card => {
                number  => '...',
                type    => 'visa',
                expire_month => '...',
                expire_year => ''',
                cvv2 => ''
            }}
        ],
        transactions => [{
            amount => {
                total    => 19.95,
                currency => "USD"
            },
        }]
    });

To learn more about the contents of REST request refer to PayPal's REST API documentation located on https://developer.paypal.com/webapps/developer/docs/api/

L<rest()> really shines if you decided to subclass Net::PayPal.

=head1 GOING LIVE

All the above methods invoke the sandbox API hosted at api.sandbox.paypal.com. Once you're done developing your tool you must go live by calling live(1)
BEFORE calling new():

    Net::PayPal->live( 1 );
    my $pp = Net::PayPal->new($client_id, $secret);


=head1 SEE ALSO

=over 4

=item L<Business::PayPal::API>

=item L<Business::PayPal::IPN>

=item L<Business::OnlinePayment::PayPal>

=back

=head1 CREDITS

Net::PayPal relies on the following Perl modules. Without these writing this tool would've been very painful, to say the least:

=over 4

=item *

L<Crypt::SSLeay> by Gisle Aas and et. al.

=item *

L<Crypt::Blowfish> by Systemics Ltd. and et. al.

=item *

L<Crypt::CBC> by Lincoln Stein

=item *

L<Cache::FileCache> by DeWitt Clinton

=item *

L<LWP> by Gisle Aas

=item *

L<JSON> by Makamaka Hannyaharamitu


=back

=head1 AUTHOR

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Sherzod B. Ruzmetov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

