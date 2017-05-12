package Mojolicious::Plugin::StripePayment;

=head1 NAME

Mojolicious::Plugin::StripePayment - Make payments using stripe.com

=head1 VERSION

0.03

=head1 DESCRIPTION

L<Mojolicious::Plugin::StripePayment> is a plugin for the L<Mojolicious> web
framework which allow you to do payments using L<https://stripe.com>.

This module is EXPERIMENTAL. The API can change at any time. Let me know
if you are using it.

=head1 SYNOPSIS

=head2 Simple API

  use Mojolicious::Lite;
  plugin StripePayment => { secret => $ENV{SUPER_SECRET_STRIPE_KEY} };

  # Need this form data:
  # amount=100&stripeToken=tok_123
  post '/charge' => sub {
    my $c = shift;
    $c->delay(
      sub { $c->stripe->create_charge({}, shift->begin) },
      sub {
        my ($delay, $err, $res) = @_;
        return $c->reply->exception($err) if $err;
        return $c->render(text => 'Charge created!');
      },
    );
  };

=head2 With local database

  use Mojolicious::Lite;

  plugin StripePayment => {
    secret  => $ENV{SUPER_SECRET_STRIPE_KEY},
    auto_capture => 0, # need to disable auto capture of payments
  };

  my $pg = Mojo::Pg->new;

  # Need this form data:
  # amount=100&stripeToken=tok_123
  post '/charge' => sub {
    my $c = shift;
    $c->delay(
      sub { $c->stripe->create_charge({}, shift->begin) },
      sub {
        my ($delay, $err, $charge) = @_;
        die $err if $err;
        $delay->pass($charge);
        $pg->db->query(
          "INSERT INTO payments (id, uid, amount, status) (?, ?, ?)",
          $charge->{id}, $c->session("uid"), $c->param("amount"), "created"
          $delay->begin
        );
      },
      sub {
        my ($delay, $charge, $err, $res) = @_;
        die $err if $err;
        $c->stripe->capture_charge($charge, $delay->begin);
      },
      sub {
        my ($delay, $charge) = @_;
        die $err if $err;
        $pg->query(
          "UPDATE payments SET status=? WHERE id=?",
          "captured", $charge->{id},
          $delay->begin
        );
      },
      sub {
        my ($delay, $err, $res) = @_;
        $c->app->log->error($err) if $err;
        $c->render(text => "Payment captured.");
      },
    );
  };

=head2 Testing mode

  use Mojolicious::Lite;

  plugin StripePayment => { mocked => 1 };

Setting C<mocked> will enable this plugin to work without an actual connection
to stripe.com. This is done by replicating the behavior of Stripe. This is
especially useful when writing unit tests.

The following routes will be added to your application to mimic Stripe:

=over 4

=item * POST /mocked/stripe-payment/charges

=item * POST /mocked/stripe-payment/charges/:id/capture

=item * GET /mocked/stripe-payment/charges/:id

=back

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::UserAgent;
use constant DEBUG => $ENV{MOJO_STRIPE_DEBUG} || 0;

our $VERSION = '0.03';

my @CAPTURE_KEYS = qw( amount application_fee receipt_email statement_descriptor );
my @CHARGE_KEYS
  = qw( amount application_fee receipt_email statement_descriptor currency customer source description capture );

# Subject for change
our $MOCKED_RESPONSE = {
  status => 200,
  json   => {
    id                   => 'ch_15ceESLV2Qt9u2twk0Arv0Z8',
    object               => 'charge',
    created              => time,
    paid                 => \1,
    status               => 'succeeded',
    refunded             => \0,
    source               => {},
    balance_transaction  => 'txn_14sJxWLV2Qt9u2tw35SuFG9X',
    failure_message      => undef,
    failure_code         => undef,
    amount_refunded      => 0,
    customer             => undef,
    invoice              => undef,
    dispute              => 0,
    statement_descriptor => undef,
    fraud_details        => {},
    receipt_number       => undef,
    shipping             => undef,
    refunds              => {},
  }
};

=head1 ATTRIBUTES

=head2 auto_capture

  $bool = $self->auto_capture; # default true

Whether or not to immediately capture the charge. When false, the charge
issues an authorization (or pre-authorization), and will need to be
captured later.

This is useful if you want to update your local database with information
regarding the charge.

=head2 base_url

  $str = $self->base_url;

This is the location to Stripe payment solution. Will be set to
L<https://api.stripe.com/v1>.

=head2 pub_key

  $str = $self->pub_key;

The value for public API key. Available in the Stripe admin gui.

=head2 currency_code

  $str = $self->currency_code;

The currency code, following ISO 4217. Default is "USD".

=head2 secret

  $str = $self->secret;

The value for the private API key. Available in the Stripe admin gui.

=cut

has base_url      => 'https://api.stripe.com/v1';
has auto_capture  => 1;
has currency_code => 'USD';
has pub_key       => 'pk_test_not_secret_at_all';
has secret        => 'sk_test_super_secret_key';
has _ua           => sub { Mojo::UserAgent->new; };

=head1 HELPERS

=head2 stripe.capture_charge

  $c->stripe->capture_charge(\%args, sub { my ($c, $err, $json) = @_; });

Used to capture a payment from a previously created charge object.

C<$err> is a string describing the error. Will be empty string on success.
C<$json> is a charge object. See L<https://stripe.com/docs/api/curl#capture_charge>
for more details.

C<%args> need to contain "id", but can also contain any of amount,
application_fee, receipt_email and/or statement_descriptor.

=head2 stripe.create_charge

  $c->stripe->create_charge(\%args, sub { my ($c, $err, $json) = @_; });

Used to create a charge object.

C<$err> is a string describing the error. Will be empty string on success.
C<$json> is a charge object. See L<https://stripe.com/docs/api/curl#create_charge>
for more details.

C<%args> can have any of...

=over 4

=item * amount

This value is required. Default to "amount" from L<Mojolicious::Controller/param>.

=item * application_fee

See L<https://stripe.com/docs/api/curl#create_charge>.

=item * capture

Defaults to L</auto_capture>.

=item * description

Defaults to "description" from L<Mojolicious::Controller/param>.

=item * currency

Defaults to L</currency_code>.

=item * customer

See L<https://stripe.com/docs/api/curl#create_charge>.

=item * receipt_email

Default to "stripeEmail" from L<Mojolicious::Controller/param>.

=item * statement_descriptor

See L<https://stripe.com/docs/api/curl#create_charge>.

=item * source

This value is required. Alias: "token".

Defaults to "stripeToken" from L<Mojolicious::Controller/param>.

=back

=head2 stripe.pub_key

  $str = $c->stripe->pub_key;

Useful for client side JavaScript. See als L<https://stripe.com/docs/tutorials/checkout>.

=head2 stripe.retrieve_charge

  $c->stripe->retrieve_charge({id => $str}, sub { my ($c, $err, $json) = @_; });

Used to retrieve a charge object.

C<$err> is a string describing the error. Will be empty string on success.
C<$json> is a charge object. See L<https://stripe.com/docs/api/curl#charge_object>
for more details.

=head1 METHODS

=head2 register

  $app->plugin(StripePayment => \%config);

Called when registering this plugin in the main L<Mojolicious> application.

=cut

sub register {
  my ($self, $app, $config) = @_;

  # copy config to this object
  for (grep { $self->can($_) } keys %$config) {
    $self->{$_} = $config->{$_};
  }

  # self contained
  $self->_mock_interface($app, $config) if $config->{mocked};

  $app->helper('stripe.capture_charge'  => sub { $self->_capture_charge(@_); });
  $app->helper('stripe.create_charge'   => sub { $self->_create_charge(@_); });
  $app->helper('stripe.pub_key'         => sub { $self->pub_key; });
  $app->helper('stripe.retrieve_charge' => sub { $self->_retrieve_charge(@_); });
}

sub _capture_charge {
  my ($self, $c, $args, $cb) = @_;
  my $url = Mojo::URL->new($self->base_url)->userinfo($self->secret . ':');
  my %form;

  $args->{id} or return $c->$cb('id is required', {});

  for my $k (@CAPTURE_KEYS) {
    $form{$k} = $args->{$k} if defined $args->{$k};
  }

  if (defined $form{statement_descriptor} and 22 < length $form{statement_descriptor}) {
    return $c->$cb('statement_descriptor is too long', {});
  }

  push @{$url->path->parts}, 'charges', $args->{id}, 'capture';
  warn "[StripePayment] Capture $url\n" if DEBUG;

  Mojo::IOLoop->delay(
    sub { $self->_ua->post($url, form => \%form, shift->begin); },
    sub { $c->$cb($self->_tx_to_res($_[1])); },
  );

  return $c;
}

sub _create_charge {
  my ($self, $c, $args, $cb) = @_;
  my $url = Mojo::URL->new($self->base_url)->userinfo($self->secret . ':');
  my %form;

  for my $k (@CHARGE_KEYS) {
    $form{$k} = $args->{$k} if defined $args->{$k};
  }

  $form{amount}   ||= $c->param('amount');
  $form{currency} ||= $self->currency_code;
  $form{description} = $c->param('description') || '' unless defined $form{description};
  $form{receipt_email} ||= $c->param('stripeEmail') if $c->param('stripeEmail');
  $form{source} ||= $args->{token} || $c->param('stripeToken');
  $form{capture} = ($form{capture} // $self->auto_capture) ? 'true' : 'false';

  $self->_expand(\%form, metadata => $args) if ref $args->{metadata};
  $self->_expand(\%form, shipping => $args) if ref $args->{shipping};

  if (defined $form{statement_descriptor} and 22 < length $form{statement_descriptor}) {
    return $c->$cb('statement_descriptor is too long', {});
  }

  $form{amount}   or return $c->$cb('amount is required',       {});
  $form{currency} or return $c->$cb('currency is required',     {});
  $form{source}   or return $c->$cb('source/token is required', {});

  push @{$url->path->parts}, 'charges';
  warn "[StripePayment] Charge $url $form{amount} $form{currency}\n" if DEBUG;

  Mojo::IOLoop->delay(
    sub { $self->_ua->post($url, form => \%form, shift->begin); },
    sub { $c->$cb($self->_tx_to_res($_[1])); },
  );

  return $c;
}

sub _expand {
  my ($self, $form, $ns, $args) = @_;

  while (my ($k, $v) = each %{$args->{$ns}}) {
    $form->{"$ns\[$k\]"} = $v;
  }
}

sub _mock_interface {
  my ($self, $app) = @_;
  my $secret = $self->secret;

  $self->_ua->server->app($app);
  $self->base_url('/mocked/stripe-payment');
  push @{$app->renderer->classes}, __PACKAGE__;

  my $metadata = sub {
    my $c = shift;
    my %metadata;
    for my $k (grep {/^metadata/} $c->req->body_params->names) {
      my $n = $k =~ /^metadata\[\w+\]/ ? $1 : 'unknown';
      $metadata{$n} = $c->param($k);
    }
    return \%metadata;
  };

  $app->routes->post(
    '/mocked/stripe-payment/charges' => sub {
      my $c = shift;
      if ($c->req->url->to_abs->userinfo eq "$secret:") {
        local $MOCKED_RESPONSE->{json}{amount}   //= $c->param('amount');
        local $MOCKED_RESPONSE->{json}{captured} //= $c->param('capture') // 1 ? \1 : \0;
        local $MOCKED_RESPONSE->{json}{currency} //= lc $c->param('currency');
        local $MOCKED_RESPONSE->{json}{description} //= $c->param('description') || '';
        local $MOCKED_RESPONSE->{json}{livemode} //= $secret =~ /test/ ? \0 : \1;
        local $MOCKED_RESPONSE->{json}{metadata} //= $metadata->($c);
        local $MOCKED_RESPONSE->{json}{receipt_email} //= $c->param('receipt_email');
        $c->render(%$MOCKED_RESPONSE);
      }
      else {
        $c->render(json => {error => {message => 'Bad secret!', type => 'invalid_request_error'}}, status => 400);
      }
    }
  );
  $app->routes->post(
    '/mocked/stripe-payment/charges/:id/capture' => sub {
      my $c = shift;
      if ($c->req->url->to_abs->userinfo eq "$secret:") {
        local $MOCKED_RESPONSE->{json}{amount} //= $c->param('amount');
        local $MOCKED_RESPONSE->{json}{captured} = \1;
        local $MOCKED_RESPONSE->{json}{livemode} //= $secret =~ /test/ ? \0 : \1;
        local $MOCKED_RESPONSE->{json}{receipt_email} //= $c->param('receipt_email');
        $c->render(%$MOCKED_RESPONSE);
      }
      else {
        $c->render(json => {error => {message => 'Bad secret!', type => 'invalid_request_error'}}, status => 400);
      }
    }
  );
  $app->routes->get(
    '/mocked/stripe-payment/charges/:id' => sub {
      my $c = shift;
      if ($c->req->url->to_abs->userinfo ne "$secret:") {
        $c->render(json => {error => {message => 'Bad secret!', type => 'invalid_request_error'}}, status => 400);
      }
      elsif (my $id = $c->param('id')) {
        local $MOCKED_RESPONSE->{id} = $id;
        $c->render(%$MOCKED_RESPONSE);
      }
      else {
        $c->render(json => {error => {message => 'Bad secret!', type => 'invalid_request_error'}}, status => 400)
          unless $c->param('id');
      }
    }
  );
}

sub _retrieve_charge {
  my ($self, $c, $args, $cb) = @_;
  my $url = Mojo::URL->new($self->base_url)->userinfo($self->secret . ':');

  push @{$url->path->parts}, 'charges', $args->{id} || 'invalid';
  warn "[StripePayment] Retrieve charge $url\n" if DEBUG;

  Mojo::IOLoop->delay(sub { $self->_ua->get($url, shift->begin); }, sub { $c->$cb($self->_tx_to_res($_[1])); });

  return $c;
}

sub _tx_to_res {
  my ($self, $tx) = @_;
  my $error = $tx->error     || {};
  my $json  = $tx->res->json || {};
  my $err   = '';

  if ($error->{code} or $json->{error}) {
    my $message = $json->{error}{message} || $json->{error}{type} || $error->{message};
    my $type    = $json->{error}{param}   || $json->{error}{code} || $error->{code};

    $err = sprintf '%s: %s', $type || 'Unknown', $message || 'Could not find any error message.';
  }

  return $err, $json;
}

=head1 SEE ALSO

=over 4

=item * Overview

L<https://stripe.com/docs>

=item * API

L<https://stripe.com/docs/api>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
