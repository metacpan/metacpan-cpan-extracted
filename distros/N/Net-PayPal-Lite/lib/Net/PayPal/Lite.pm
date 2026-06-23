package Net::PayPal::Lite;
use strict;
use warnings;

use JSON;
use Carp 'croak';
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request;

our $VERSION = '0.02';

my $json = JSON->new->allow_nonref;

sub live {
    my $self = shift;
    return ! $self->sandbox( scalar @_ ? !$_[0] : () );
}

sub sandbox {
    my $self = shift;
    if (scalar @_) {
        $self->{sandbox} = !! $_[0];
    }
    return $self->{sandbox};
}

sub endpoint {
    my ($self) = @_;
    $self->sandbox ? 'https://api.sandbox.paypal.com'
                   : 'https://api.paypal.com';
}

sub new {
    my $class = shift;
    my $args = (ref $_[0] ? $_[0] : {@_});

    croak 'please provide a client_id and a secret'
        unless $args->{client_id} and $args->{secret};

    croak 'passing both sandbox and live attributes is not allowed'
        if exists $args->{sandbox} and exists $args->{live};

    croak '"cache_transform" hashref must have "in" and "out" subrefs'
        if exists $args->{cache_transform}
          && (ref $args->{cache_transform} ne 'HASH'
               || !exists $args->{cache_transform}{in}
               || !exists $args->{cache_transform}{out}
               || ref $args->{cache_transform}{in}  ne 'CODE'
               || ref $args->{cache_transform}{out} ne 'CODE'
           );

    return bless {
        client_id        => $args->{client_id},
        secret           => $args->{secret},
        user_agent       => $args->{user_agent} || _create_ua(),
        cache_transform  => $args->{cache_transform},
        cache            => $args->{cache}
                         || _create_cache($args->{cache_dir}),
        sandbox          => (  exists $args->{sandbox} ?  $args->{sandbox}
                             : exists $args->{live}    ? !$args->{live}
                             : 1
                         ),
    }, $class;
}

sub access_token {
    my $self = shift;

    if (@_) {
        my ($token, $expiration) = @_;
        $self->_set_cached_access_token($token, $expiration || () );
        return $token;
    }
    elsif ( my $token = $self->_get_cached_access_token ) {
        return $token;
    }
    else {
        my ($token ,$expiration) = $self->_get_access_token_from_paypal;
        $self->_set_cached_access_token($token, $expiration);
        return $token;
    }
}


sub _get_access_token_from_paypal {
    my ($self) = @_;

    my $header = HTTP::Headers->new(
        'Content-Type'    => 'application/x-www-form-urlencoded',
        'Accept'          => 'application/json',
        'Accept-Language' => 'en_US'
    );

    $header->authorization_basic( $self->{client_id}, $self->{secret} );

    my $req = HTTP::Request->new(
        'POST' => $self->endpoint . '/v1/oauth2/token',
        $header,
        'grant_type=client_credentials'
    );

    my $res = $self->{user_agent}->request($req);

    croak 'Authorization failed: ' . $res->status_line . ', ' . $res->content
        unless $res->is_success;

    my $res_hash = _json_decode( $res->content );

    return ($res_hash->{access_token}, $res_hash->{expires_in});
}

sub _set_cached_access_token {
    my ($self, $token, $expiration) = @_;

    $token = $self->{cache_transform}{in}->($token)
        if $self->{cache_transform};

    $self->{cache}->set( $self->{client_id}, $token, $expiration );
}

sub _get_cached_access_token {
    my ($self) = @_;

    my $token = $self->{cache}->get( $self->{client_id} );

    $token = $self->{cache_transform}{out}->($token)
        if $self->{cache_transform};

    return $token;
}

sub _create_cache {
    my ($cache_root) = @_;
    require Cache::FileCache;
    return Cache::FileCache->new({
        namespace  => 'PayPalAPI',
        ($cache_root ? (cache_root => $cache_root) : ()),
    });
}

sub _create_ua {
    require LWP::UserAgent;
    return LWP::UserAgent->new( agent => "Net-PayPal-Lite/$VERSION" );
}

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
    my ($self, $method, $path, $json) = @_;

    my $target_uri = $self->endpoint . $path;
    my $token = $self->access_token;

    my $req = HTTP::Request->new(
        $method => $target_uri,
        [
            'Content-Type'  => 'application/json',
            'Authorization' => "Bearer $token"
        ]
    );

    if ($json) {
        $json = _json_encode($json) if ref $json;
        $req->content($json);
    }

    my $res = $self->{user_agent}->request($req);

    if ($res->is_success) {
        return _json_decode( $res->content );
    }
    else {
        if ( my $content = $res->content ) {
            my $error = _json_decode( $res->content );
            $self->error( $res->content );
        }
        else {
            $self->error( $res->status_line );
        }
        return undef;
    }
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
            payment_method      => 'credit_card',
            funding_instruments => [ { credit_card => \%credit_card } ]
        },
        transactions => [
            {
                amount => {
                    total    => $data->{amount},
                    currency => $data->{currency} || 'USD'
                },
            }
        ]
    };

    if ( $data->{redirect_urls} ) {
        $request_hash->{redirect_urls} = $data->{redirect_urls};
    }

    return $self->rest( 'POST', '/v1/payments/payment', _json_encode($request_hash) );
}

sub stored_cc_payment {
    my $self = shift;
    my ($data) = @_;

    unless ( $data->{id} ) {
        croak 'stored_cc_payment(): "id" is missing';
    }

    my $request_hash = {
        intent => 'sale',
        payer  => {
            payment_method      => 'credit_card',
            funding_instruments => [ { credit_card_token => { credit_card_id => $data->{id} } } ]
        },
        transactions => [
            {
                amount => {
                    total    => $data->{amount},
                    currency => $data->{currency} || 'USD'
                },
            }
        ]
    };

    if ( $data->{redirect_urls} ) {
        $request_hash->{redirect_urls} = $data->{redirect_urls};
    }

    return $self->rest( 'POST', '/v1/payments/payment', _json_encode($request_hash) );
}

sub get_payment {
    my $self = shift;
    my ($id) = @_;

    unless ($id) {
        croak 'get_payment(): Invalid Payment ID';
    }

    return $self->rest( 'GET', "/v1/payments/payment/$id" );
}

sub get_payments {
    my $self = shift;

    return $self->rest( 'GET', '/v1/payments/payment' );
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
    return $self->rest( 'POST', '/v1/vault/credit-card', _json_encode( \%credit_card ) );
}

sub get_cc {
    my $self = shift;
    my ($id) = @_;
    return $self->rest( 'GET', "/v1/vault/credit-card/$id" );
}

sub error {
    my ($self, $message) = @_;
    return $self->{last_error} unless $message;
    return $self->{last_error} = $message
}

1;
__END__

=head1 NAME

Net::PayPal::Lite - unofficial Perl extension for PayPal's REST API (Lite version)

=head1 SYNOPSIS

    use Net::PayPal::Lite

    my $p = Net::PayPal::Lite->new(
        client_id => $client_id,
        secret    => $secret,
    );

    my $payment = $p->cc_payment({
        cc_number       => '4111111111111111',
        cc_type         => 'visa',
        cc_expire_month => 3,
        cc_expire_year  => 2099,
        amount          => 19.95,
    });

    unless ( $payment ) {
        die $p->error;
    }

    unless ( $payment->{state} eq "approved" ) {
        printf("Your payment was not approved");
    }


=head1 DESCRIPTION

Net::PayPal::Lite implements PayPal's REST API. Visit L<http://developer.paypal.com>
for further information.

This is a "lite" fork of L<Net::PayPal> that does not store secrets in encrypted files.

To start using Net::PayPal::Lite the following actions must be completed to gain access to API endpoints:

=over 4

=item 1 L<Sign up|http://developer.paypal.com> for a (free) developer account.

=item 2 Under "Applications" tab (after signing into developer.paypal.com) make note of C<secret> and C<client_id>. You will need these two identifiers
to interact with PayPal's API server

=item 3 Create Net::PayPal::Lite instance using C<secret> and C<client_id> identifiers.

=back

=head1 METHODS

Following methods are available

=head2 new( %ARGS );

    my $paypal = Net::PayPal::Lite->new(
        client_id => '1234',
        secret    => 'abcd',
    );

Creates and returns an instance of Net::PayPal::Lite class.

Accepts the following arguments in a hash or hashref:

=over 4

=item * client_id - The client id for your app, as provided by PayPal.
B<Mandatory>.

=item * secret - The secret for your app, as provided by PayPal. B<Mandatory>.

=item * sandbox - Set the target url 

=back

=head3 Safekeeping your cached access token

PayPal's REST API forces you to provide an access token on every query. That
token comes with a (sometimes very short) expiration date, rendering requests
very expensive - imagine having to ask for a new acces token every time you
make a request to the API!

To prevent that while also allowing different processes to share the same
access token, we store it in cache, using L<Cache::Cache>'s FileCache engine.

Problem is, caching to the filesystem defaults to a I<public> directory,
which might be readable by others. While that's kind of the point, it
is worth noticing that anyone whith read access to the temporary directory
in your filesystem will be able to read it (and perform operations on the
REST API on your behalf!).

There are several ways to make this safe:

=item * use the C<cache_dir> argument to save the cache file in a protected
directory of your choosing - probably the same place where you store your
client_id and secret, which are even more sensitive.

=item * use the C<cache> argument to set a different, safer, cache of your
choosing.

=item * use the C<cache_transform> argument to encrypt/decrypt your access
key. The example below encrypts your key using the Blowfish cipher, with
the paypal secret as key:

    use Net::PayPal::Lite;
    use Crypt::CBC;

    my ($client_id, $secret) = fetch_my_paypal_data();

    my $cipher = Crypt::CBC->new( -key => $secret, -cipher => 'Blowfish' );

    my $paypal = Net::PayPal::Lite->new({
        client_id       => $client_id,
        secret          => $secret,
        cache_transform => {
            in  => sub { $cipher->encrypt(@_) },
            out => sub { $cipher->decrypt(@_) },
        }

=back

=head3 cc_payment(\%data)

Charges a credit card:

    my $payment = $p->cc_payment({
        cc_number       => '4111111111111111',
        cc_type         => 'visa',
        cc_expire_month => 3,
        cc_expire_year  => 2099,
        first_name      => 'Jane',
        last_name       => 'Doe',
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
        cc_number       => '4111111111111111',
        cc_type         => 'visa',
        cc_expire_month => '3',
        cc_expire_year  => '2099',
        cvv2            => '420',
        first_name      => 'Jane',
        last_name       => 'Doe'
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
methods of Net::PayPal::Lite rely on this method to make things happen. It takes care of all OAuth2 specific authentication that PayPal requires.

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

L<rest()> really shines if you decided to subclass Net::PayPal::Lite.

=head1 GOING LIVE

All the above methods invoke the sandbox API hosted at api.sandbox.paypal.com. Once you're done developing your tool you must go live by calling live(1)
BEFORE calling new():

    Net::PayPal::Lite->live( 1 );
    my $pp = Net::PayPal::Lite->new($client_id, $secret);


=head1 SEE ALSO

=over 4

=item L<Net::PayPal> (this module is a fork of it)

=item L<Business::Net::PayPal::Lite>

=item L<Business::PayPal::IPN>

=item L<Business::OnlinePayment::PayPal>

=back

=head1 CREDITS

Net::PayPal::Lite is an immediate fork of Sherzod B. Ruzmetov's excellent Net::PayPal, which sadly hasn't been updated in a while.

B<< Net::PayPal::Lite is NOT affiliated with PayPal nor PayPal, Inc. in any way. >>

PayPal is a trademark of PayPal, Inc.

=head1 AUTHOR

Sherzod B. Ruzmetov <sherzodr@cpan.org> (original source code author)
Breno G. de Oliveira <garu@cpan.org> (fork maintainer)

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
