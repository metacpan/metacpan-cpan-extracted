package Mojolicious::Plugin::PayPal;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON 'j';
use Mojo::UserAgent;
use constant DEBUG => $ENV{MOJO_PAYPAL_DEBUG} || 0;


our $VERSION = '0.07';

has base_url              => 'https://api.sandbox.paypal.com';
has client_id             => 'dummy_client';
has currency_code         => 'USD';
has transaction_id_mapper => undef;
has secret                => 'dummy_secret';
has _ua                   => sub { Mojo::UserAgent->new; };

sub process_payment {
  my ($self, $c, $args, $cb) = @_;
  my %body;

  $args->{cancel} //= $c->param('return_url') ? 0 : 1;
  $args->{token} ||= $c->param('token')
    or return $self->$cb($self->_error('token missing in input'));
  $args->{payer_id} ||= $c->param('PayerID')
    or return $self->$cb($self->_error('PayerID missing in input'));

  %body = (payer_id => $args->{payer_id});

  $c->delay(
    sub {
      my ($delay) = @_;
      $self->transaction_id_mapper->($self, $args->{token}, undef, $delay->begin);
    },
    sub {
      my ($delay, $err, $transaction_id) = @_;
      return $self->$cb($self->_error($err)) if $err;
      my $url = $self->_url("/v1/payments/payment/$transaction_id/execute");
      $delay->pass($transaction_id);
      $self->_make_request_with_token($c, post => $url, j(\%body), $delay->begin);
    },
    sub {
      my ($delay, $transaction_id, $tx) = @_;
      my $res = Mojolicious::Plugin::PayPal::Res->new($tx->res);

      $res->code(0) unless $res->code;
      $res->param(transaction_id => $transaction_id);

      if ($args->{cancel}) {
        $res->param(message => 'Payment cancelled.');
        $res->param(source  => $self->base_url);
        $res->code(205);
        return $self->$cb($res);
      }

      local $@;
      eval {
        my $json = $res->json;
        my $token;

        $json->{id} or die 'No transaction ID in response from PayPal';
        $json->{state} eq 'approved' or die $json->{state};

        while (my ($key, $value) = each %{$json->{payer}{payer_info} || {}}) {
          $res->param("payer_$key" => $value);
        }

        $res->param(payer_id       => $args->{payer_id});
        $res->param(state          => $json->{state});
        $res->param(transaction_id => $json->{id});
        $res->code(200);
        $self->$cb($res);
        1;
      } or do {
        warn "[MOJO_PAYPAL] ! $@" if DEBUG;
        $self->$cb($self->_extract_error($res, $@));
      };
    },
  );

  $self;
}

sub register_payment {
  my ($self, $c, $args, $cb) = @_;
  my $register_url = $self->_url('/v1/payments/payment');
  my $redirect_url = Mojo::URL->new($args->{redirect_url} ||= $c->req->url->to_abs);
  my %body;

  $args->{amount} or return $self->$cb($self->_error('amount missing in input'));

  %body = (
    intent        => 'sale',
    redirect_urls => {
      return_url => $redirect_url->query(return_url => 1)->to_abs,
      cancel_url => $redirect_url->to_abs,
    },
    payer        => {payment_method => 'paypal',},
    transactions => [
      {
        description => $args->{description} || '',
        amount =>
          {total => $args->{amount}, currency => $args->{currency_code} || $self->currency_code,},
      },
    ],
  );

  $c->delay(
    sub {
      my ($delay) = @_;
      $self->_make_request_with_token($c, post => $register_url, j(\%body), $delay->begin);
    },
    sub {
      my ($delay, $tx) = @_;
      my $res = Mojolicious::Plugin::PayPal::Res->new($tx->res);

      $res->code(0) unless $res->code;

      local $@;
      eval {
        my $json = $res->json;
        my $token;

        $json->{id} or die 'No transaction ID in response from PayPal';
        $json->{state} eq 'created' or die $json->{state};

        for my $link (@{$json->{links}}) {
          my $key = "$link->{rel}_url";
          $key =~ s!_url_url$!_url!;
          $res->param($key => $link->{href});
        }

        $token = Mojo::URL->new($res->param('approval_url'))->query->param('token');

        $res->param(state          => $json->{state});
        $res->param(transaction_id => $json->{id});
        $res->headers->location($res->param('approval_url'));
        $res->code(302);
        $delay->pass($res);
        $self->transaction_id_mapper->($self, $token => $json->{id}, $delay->begin);
        1;
      } or do {
        warn "[MOJO_PAYPAL] ! $@" if DEBUG;
        $delay->pass($self->_extract_error($res, $@));
      };
    },
    sub {
      my ($delay, $res, $err, $id) = @_;

      return $self->$cb($self->_error($err)) if $err;
      return $self->$cb($res);
    },
  );

  $self;
}

sub register {
  my ($self, $app, $config) = @_;

  # self contained
  if (ref $config->{secret}) {
    $self->_add_routes($app);
    $self->_ua->server->app($app);
    $config->{secret} = ${$config->{secret}};
  }
  elsif ($app->mode eq 'production') {
    $config->{base_url} ||= 'https://api.paypal.com';
  }

  # copy config to this object
  for (grep { $self->$_ } keys %$config) {
    $self->{$_} = $config->{$_};
  }

  unless ($self->transaction_id_mapper) {
    $self->transaction_id_mapper(
      sub {
        my ($self, $token, $transaction_id, $cb) = @_;
        $app->log->warn("You need to set 'transaction_id_mapper' in Mojolicious::Plugin::PayPal");
        $self->$cb('', $self->{transaction_id_map}{$token} //= $transaction_id);
      }
    );
  }

  $app->helper(
    paypal => sub {
      my $c = shift;
      return $self unless @_;
      my $method = sprintf '%s_payment', shift;
      $self->$method($c, @_);
      return $c;
    }
  );
}

sub _add_routes {
  my ($self, $app) = @_;
  my $r        = $app->routes;
  my $payments = $self->{payments}
    ||= {};    # just here for debug purposes, may change without warning

  $self->base_url('/paypal');

  $r->post('/paypal/v1/oauth2/token' => {template => 'paypal/v1/oauth2/token', format => 'json'});

  $r->post(
    '/paypal/v1/payments/payment' => sub {
      my $self  = shift;
      my $token = 'EC-60U79048BN7719609';
      $payments->{$token} = $self->req->json;
      $self->render('paypal/v1/payments/payment', token => $token, format => 'json');
    }
  );

  $r->get('/paypal/webscr')->to(
    cb => sub {
      my $self = shift;
      my $token = $self->param('token') || 'missing';
      $payments->{CR87QHB7JTRSC} = $payments->{$token};    # payer_id = CR87QHB7JTRSC
      $self->render('paypal/webscr', format => 'html', payment => $payments->{$token});
    }
  );

  $r->post('/paypal/v1/payments/payment/:transaction_id/execute')->to(
    cb => sub {
      my $self = shift;
      my $payer_id = $self->req->json->{payer_id} || 'missing';
      $self->render(
        'paypal/v1/payments/payment/execute',
        payment => $payments->{$payer_id},
        format  => 'json'
      );
    }
  );

  push @{$app->renderer->classes}, __PACKAGE__;
}

sub _error {
  my ($self, $err) = @_;
  my $res = Mojolicious::Plugin::PayPal::Res->new;
  $res->code(400);
  $res->param(message => $err);
  $res->param(source  => __PACKAGE__);
  $res;
}

sub _extract_error {
  my ($self, $res, $e) = @_;
  my $err = '';    # TODO

  $res->code(500);
  $res->param(message => $err // $e);
  $res->param(source => $err ? $self->base_url : __PACKAGE__);
  $res;
}

sub _get_access_token {
  my ($self, $cb) = @_;
  my $token_url = $self->_url('/v1/oauth2/token');
  my %headers = ('Accept' => 'application/json', 'Accept-Language' => 'en_US');

  $token_url->userinfo(join ':', $self->client_id, $self->secret);
  warn "[MOJO_PAYPAL] Token URL $token_url\n" if DEBUG == 2;

  $c->delay(
    sub {
      my ($delay) = @_;
      $self->_ua->post(
        $token_url, \%headers,
        form => {grant_type => 'client_credentials'},
        $delay->begin
      );
    },
    sub {
      my ($delay, $tx) = @_;
      my $json = eval { $tx->res->json } || {};

      $json->{access_token} //= '';
      $self->$cb($self->{access_token} = $json->{access_token}, $tx);
    },
  );
}

# https://developer.paypal.com/webapps/developer/docs/integration/direct/make-your-first-call/
sub _make_request_with_token {
  my ($self, $c, $method, $url, $body, $cb) = @_;
  my %headers = ('Content-Type' => 'application/json');

  $c->delay(
    sub {    # get token unless we have it
      my ($delay) = @_;
      return $delay->pass($self->{access_token}, undef) if $self->{access_token};
      return $self->_get_access_token($delay->begin);
    },
    sub {    # abort or make request with token
      my ($delay, $token, $tx) = @_;
      return $self->$cb($tx) unless $token;
      $headers{Authorization} = "Bearer $token";
      warn "[MOJO_PAYPAL] Authorization: Bearer $token\n" if DEBUG;
      return $self->_ua->$method($url, \%headers, $body, $delay->begin);
    },
    sub {    # get token if it has expired
      my ($delay, $tx) = @_;
      return $self->_get_access_token($delay->begin) if $tx->res->code == 401;
      return $delay->pass(undef, $tx);    # success
    },
    sub {                                 # return or retry request with new token
      my ($delay, $token, $tx) = @_;
      return $self->$cb($tx) unless $token;    # return success or error $tx
      $headers{Authorization} = "Bearer $token";
      warn "[MOJO_PAYPAL] Authorization: Bearer $token\n" if DEBUG;
      return $self->_ua->$method($url, \%headers, $body, $cb);
    },
  );
}

sub _url {
  my $url = Mojo::URL->new($_[0]->base_url . $_[1]);
  warn "[MOJO_PAYPAL] URL $url\n" if DEBUG;
  $url;
}

{

  package Mojolicious::Plugin::PayPal::Res;
  use Mojo::Base 'Mojo::Message::Response';
  sub param { shift->body_params->param(@_) }
}

package Mojolicious::Plugin::PayPal;

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::PayPal - Make payments using PayPal

=head1 VERSION

0.07

=head1 DESCRIPTION

L<Mojolicious::Plugin::PayPal> is a plugin for the L<Mojolicious> web
framework which allow you to do payments using L<https://www.paypal.com|PayPal>.

This module is EXPERIMENTAL. The API can change at any time. Let me know
if you are using it.

See also L<https://developer.paypal.com/webapps/developer/docs/integration/web/accept-paypal-payment/>.

=head1 SYNOPSIS

  use Mojolicious::Lite;

  plugin PayPal => {
    secret => '...',
    client_id => '...',
  };

  # register a payment and send the visitor to PayPal payment terminal
  post '/checkout' => sub {
    my $c = shift;
    my %payment = (
      amount => $c->param('amount'),
      description => 'Some description',
    );

    $c->delay(
      sub {
        my ($delay) = @_;
        $c->paypal(register => \%payment, $delay->begin);
      },
      sub {
        my ($delay, $res) = @_;
        return $c->render(text => "Ooops!", status => $res->code) unless $res->code == 302;
        # store $res->param('transaction_id');
        $c->redirect_to($res->headers->location);
      },
    );
  };

  # after redirected back from PayPal payment terminal
  get '/checkout' => sub {
    my $c = shift;

    $c->delay(
      sub {
        my ($delay) = @_;
        $c->paypal(process => {}, $delay->begin);
      },
      sub {
        my ($delay, $res) = @_;
        return $c->render(text => $res->param("message"), status => $res->code) unless $res->code == 200;
        return $c->render(text => "yay!");
      },
    );
  };


=head2 Transaction ID mapper

You should provide a L</transaction_id_mapper>. Here is an example code on how to do that:

  $app->paypal->transaction_id_mapper(sub {
    my ($self, $token, $transaction_id, $cb) = @_;

    if($transaction_id) {
      eval { My::DB->store_transaction_id($token => $transaction_id); };
      $self->$cb($@, $transaction_id);
    }
    else {
      my $transaction_id = eval { My::DB->get_transaction_id($token)); };
      $self->$cb($@, $transaction_id);
    }
  });

=head1 ATTRIBUTES

=head2 base_url

  $str = $self->base_url;

This is the location to PayPal payment solution. Will be set to
L<https://api.paypal.com> if the mojolicious application mode is
"production" or L<https://api.sandbox.paypal.com>.

=head2 client_id

  $str = $self->client_id;

The value used as username when fetching the the access token.
This can be found in "Applications tab" in the PayPal Developer site.

=head2 currency_code

  $str = $self->currency_code;

The currency code. Default is "USD".

=head2 transaction_id_mapper

  $code = $self->transaction_id_mapper;

Holds a code used to find the transaction ID, after user has been redirected
back from PayPal terminal page.

NOTE! The default callback provided by this module does not scale and will
not work in a multi-process environment, such as running under C<hypnotoad>
or using a load balancer. You should therefor provide your own backend
solution. See L</Transaction ID mapper> for example code.

=head2 secret

  $str = $self->secret;

The value used as password when fetching the the access token.
This can be found in "Applications tab" in the PayPal Developer site.

=head1 HELPERS

=head2 paypal

  $self = $c->paypal;
  $c = $c->paypal($method => @args);

Returns this instance unless any args have been given or calls one of the
available L</METHODS> instead. C<$method> need to be without "_payment" at
the end. Example:

  $c->paypal(register => { ... }, sub {
    my ($c, $res) = @_;
    # ...
  });

=head1 METHODS

=head2 process_payment

  $self = $self->process_payment(
    $c,
    {
      token => $str, # default to $c->param("token")
      payer_id => $str, # default to $c->param("PayerID")
    },
    sub {
      my ($self, $res) = @_;
    },
  );

This is used to process the payment after a user has been redirected back
from the PayPal terminal.

See L<https://developer.paypal.com/webapps/developer/docs/api/#execute-an-approved-paypal-payment>
for details.

=head2 register_payment

  $self = $self->register_payment(
    $c,
    {
      amount => $num, # 99.90, not 9990
      redirect_url => $str, # default to current request URL
      # ...
    },
    sub {
      my ($self, $res) = @_;
    },
  );

The L</register_payment> method is used to send the required payment details
to PayPal which will later be approved by the user after being redirected
to the PayPal terminal page.

Useful C<$res> values:

=over 4

=item * $res->code

Set to 302 on success.

=item * $res->param("transaction_id")

Only set on success. An ID identifying this transaction. Generated by PayPal.

=item * $res->headers->location

Only set on success. This holds a URL to the PayPal terminal page, which
you will redirect the user to after storing the transaction ID and other
customer related details.

=back

=head2 register

  $app->plugin(PayPal => \%config);

Called when registering this plugin in the main L<Mojolicious> application.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=head1 CONTRIBUTORS

Yu Pan - C<yu.pan1005@gmail.com>

=cut

__DATA__
@@ layouts/paypal.html.ep
<!DOCTYPE html>
<html>
<head>
  <title>PayPal terminal</title>
</head>
<body>
%= content
</body>
</html>

@@ paypal/webscr.html.ep
% layout 'nets';
<h1>PayPal</h1>
<p>This is a dummy terminal. Obviously.</p>
<dl>
  <dt>Amount</dt><dd><%= $payment->{transactions}[0]{amount}{total} %> <%= $payment->{transactions}[0]{amount}{currency} %></dd>
  <dt>Payment method</dt><dd><%= $payment->{payer}{payment_method} %></dd>
</dl>
<p>
  %= link_to 'Complete payment', Mojo::URL->new($payment->{redirect_urls}{return_url})->query({ token => 'EC-60U79048BN7719609', PayerID => '42' }), class => 'back'
  %= link_to 'Cancel payment', Mojo::URL->new($payment->{redirect_urls}{cancel_url})->query({ token => 'EC-60U79048BN7719609', PayerID => '42' }), class => 'cancel'
</p>

@@ paypal/v1/oauth2/token.json.ep
{
  "scope": "https://api.paypal.com/v1/payments/.* https://api.paypal.com/v1/vault/credit-card https://api.paypal.com/v1/vault/credit-card/.*",
  "access_token": "80R95024SS305861X",
  "token_type": "Bearer",
  "app_id": "APP-6XR95014SS315863X",
  "expires_in": 28800
}

@@ paypal/v1/payments/payment.json.ep
{
  "id": "PAY-6RV70583SB702805EKEYSZ6Y",
  "create_time": "2013-03-01T22:34:35Z",
  "update_time": "2013-03-01T22:34:36Z",
  "state": "created",
  "intent": "sale",
  "payer": {
    "payment_method": "paypal"
  },
  "transactions": [
    {
      "amount": {
        "total": "7.47",
        "currency": "USD",
        "details": {
          "subtotal": "7.47"
        }
      },
      "description": "This is the payment transaction description."
    }
  ],
  "links": [
    {
      "href": "/paypal/v1/payments/payment/PAY-6RV70583SB702805EKEYSZ6Y",
      "rel": "self",
      "method": "GET"
    },
    {
      "href": "/paypal/webscr?cmd=_express-checkout&token=EC-60U79048BN7719609",
      "rel": "approval_url",
      "method": "REDIRECT"
    },
    {
      "href": "/paypal/v1/payments/payment/PAY-6RV70583SB702805EKEYSZ6Y/execute",
      "rel": "execute",
      "method": "POST"
    }
  ]
}

@@ paypal/v1/payments/payment/execute.json.ep
{
  "id": "PAY-6RV70583SB702805EKEYSZ6Y",
  "create_time": "2013-01-30T23:44:26Z",
  "update_time": "2013-01-30T23:44:28Z",
  "state": "approved",
  "intent": "sale",
  "payer": {
    "payment_method": "paypal",
    "payer_info": {
      "email": "bbuyer@example.com",
      "first_name": "Betsy",
      "last_name": "Buyer",
      "payer_id": "CR87QHB7JTRSC"
    }
  },
  "transactions": [
    {
      "amount": {
        "total": "7.47",
        "currency": "USD",
        "details": {
          "tax": "0.04",
          "shipping": "0.06"
        }
      },
      "description": "This is the payment transaction description.",
      "related_resources": [
        {
          "sale": {
            "id": "1KE4800207592173L",
            "create_time": "2013-01-30T23:44:26Z",
            "update_time": "2013-01-30T23:44:28Z",
            "state": "completed",
            "amount": {
              "total": "7.47",
              "currency": "USD"
            },
            "parent_payment": "PAY-6RV70583SB702805EKEYSZ6Y",
            "links": [
              {
                "href": "https://api.sandbox.paypal.com/v1/payments/sale/1KE4800207592173L",
                "rel": "self",
                "method": "GET"
              },
              {
                "href": "https://api.sandbox.paypal.com/v1/payments/sale/1KE4800207592173L/refund",
                "rel": "refund",
                "method": "POST"
              },
              {
                "href": "https://api.sandbox.paypal.com/v1/payments/payment/PAY-6RV70583SB702805EKEYSZ6Y",
                "rel": "parent_payment",
                "method": "GET"
              }
            ]
          }
        }
      ]
    }
  ],
  "links": [
    {
      "href": "https://api.sandbox.paypal.com/v1/payments/payment/PAY-34629814WL663112AKEE3AWQ",
      "rel": "self",
      "method": "GET"
    }
  ]
}
