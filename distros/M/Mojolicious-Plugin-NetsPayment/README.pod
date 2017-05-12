package Mojolicious::Plugin::NetsPayment;

=head1 NAME

Mojolicious::Plugin::NetsPayment - Make payments using Nets

=head1 VERSION

0.04

=head1 DESCRIPTION

L<Mojolicious::Plugin::NetsPayment> is a plugin for the L<Mojolicious> web
framework which allow you to do payments using L<http://www.betalingsterminal.no|Nets>.

This module is EXPERIMENTAL. The API can change at any time. Let me know
if you are using it.

=head1 SYNOPSIS

  use Mojolicious::Lite;

  plugin NetsPayment => {
    merchant_id => '...',
    token => '...',
  };

  # register a payment and send the visitor to Nets payment terminal
  post '/checkout' => sub {
    my $self = shift->render_later;
    my %payment = (
      amount => $self->param('amount'),
      order_number => scalar $self->param('order_number'),
    );

    Mojo::IOLoop->delay(
      sub {
        my ($delay) = @_;
        $self->nets(register => \%payment, $delay->begin);
      },
      sub {
        my ($delay, $res) = @_;
        return $self->render(text => "Ooops!", status => $res->code) unless $res->code == 302;
        # store $res->param('transaction_id');
        $self->redirect_to($res->headers->location);
      },
    );
  };

  # after redirected back from Nets payment terminal
  get '/checkout' => sub {
    my $self = shift->render_later;

    Mojo::IOLoop->delay(
      sub {
        my ($delay) = @_;
        $self->nets(process => {}, $delay->begin);
      },
      sub {
        my ($delay, $res) = @_;
        return $self->render(text => $res->param("message"), status => $res->code) unless $res->code == 200;
        # store $res->param('transaction_id') and $res->param('authorization_id');
        $self->render(text => "yay!");
      },
    );
  };

=head2 Self contained

  use Mojolicious::Lite;

  plugin NetsPayment => {
    merchant_id => '...',
    token => \ "dummy",
  };

Setting token to a reference will enable this plugin to work without a working
nets backend. This is done by replicating the behavior of Nets. This is
especially useful when writing unit tests.

The following routes will be added to your application to mimic nets:

=over 4

=item * /nets/Netaxept/Process.aspx

L<http://www.betalingsterminal.no/Netthandel-forside/Teknisk-veiledning/API/Process/>.

=item * /nets/Netaxept/Query.aspx

L<http://www.betalingsterminal.no/Netthandel-forside/Teknisk-veiledning/API/Query/>.

=item * /nets/Netaxept/Register.aspx

L<http://www.betalingsterminal.no/Netthandel-forside/Teknisk-veiledning/API/Register/>.

=item * /nets/Terminal/default.aspx

L<http://www.betalingsterminal.no/Netthandel-forside/Teknisk-veiledning/Terminal/>.

=back

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::UserAgent;
use constant DEBUG => $ENV{MOJO_NETS_DEBUG} || 0;

our $VERSION = '0.04';

=head1 ATTRIBUTES

=head2 base_url

  $str = $self->base_url;

This is the location to Nets payment solution. Will be set to
L<https://epayment.nets.eu> if the mojolicious application mode is
"production" or L<https://test.epayment.nets.eu> if not.

=head2 currency_code

  $str = $self->currency_code;

The currency code, following ISO 4217. Default is "NOK".

=head2 merchant_id

  $str = $self->merchant_id;

The value for the merchant ID, can be found in the Nets admin gui.

=head2 token

  $str = $self->token;

The value for the merchant ID, can be found in the Nets admin gui.

=cut

has currency_code => 'NOK';
has merchant_id => 'dummy_merchant';
has token => 'dummy_token';
has base_url => 'https://test.epayment.nets.eu';
has _ua => sub { Mojo::UserAgent->new; };

=head1 HELPERS

=head2 nets

  $self = $c->nets;
  $c = $c->nets($method => @args);

Returns this instance unless any args have been given or calls one of the
avaiable L</METHODS> instead. C<$method> need to be without "_payment" at
the end. Example:

  $c->nets(register => { ... }, sub {
    my ($c, $res) = @_;
    # ...
  });

=head1 METHODS

=head2 process_payment

  $self = $self->process_payment(
    $c,
    {
      transaction_id => $str, # default to $c->param("transactionId")
      operation => $str, # default to AUTH
      # ...
    },
    sub {
      my ($self, $res) = @_;
    },
  );

From L<http://www.betalingsterminal.no/Netthandel-forside/Teknisk-veiledning/API/Process/>:

  All financial transactions are encapsulated by the "Process"-call.
  Available financial transactions are AUTH, SALE, CAPTURE, CREDIT
  and ANNUL.

Useful C<$res> values:

=over 4

=item * $res->code

Holds the response code from Nets. Will be set to 500 by this module, if the
message could not be parsed.

=item * $res->param("code")

"OK" on success, something else on failure.

=item * $res->param("authorization_id")

Only set on success. An ID identifying this authorization.

=item * $res->param("operation")

Only set on success. This is the same value as given to this method.

=item * $res->param("transaction_id")

Only set on success. This is the same value as given to this method.

=item * $res->param("message")

Only set if "code" is not "OK". Holds a description of the error.
See also L</ERROR HANDLING>.

=item * $res->param("source")

Only set if "code" is not "OK". See also L</ERROR HANDLING>.

=back

=cut

sub process_payment {
  my ($self, $c, $args, $cb) = @_;
  my $process_url = $self->_url('/Netaxept/Process.aspx');

  $args = { transaction_id => $args } unless ref $args;
  $args->{operation} ||= 'AUTH';
  $args->{transaction_id} ||= $c->param('transactionId') or return $self->$cb($self->_error('transaction_id missing in input'));

  $process_url->query({
    merchantId    => $self->merchant_id,
    token         => $self->token,
    operation     => $args->{operation} || 'AUTH',
    transactionId => $args->{transaction_id},
    $self->_camelize($args),
  });

  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      $self->_ua->get($process_url, $delay->begin);
    },
    sub {
      my ($delay, $tx) = @_;
      my $res = Mojolicious::Plugin::NetsPayment::Res->new($tx->res);

      $res->code(0) unless $res->code;

      local $@;
      eval {
        my $body = $res->dom->at('ProcessResponse');
        my $code = $body->at('ResponseCode')->text;

        if($code eq 'OK') {
          $res->code(200);
          $res->param(authorization_id => $body->at('AuthorizationId')->text);
          $res->param(operation => $body->at('Operation')->text);
          $res->param(transaction_id => $body->at('TransactionId')->text);
        }
        else {
          $res->code(500) if $res->code == 200;
          $res->param(message => $body->at('ResponseText')->text);
          $res->param(source => $body->at('ResponseSource')->text);
        }

        $res->param(code => $code);
      } or do {
        warn "[MOJO_NETS] ! $@" if DEBUG;
        $self->_extract_error($res, $@);
      };

      $self->$cb($res);
    },
  );

  $self;
}

=head2 query_payment

  $self = $self->query_payment(
    $c,
    {
      transaction_id => $str,
    },
    sub {
      my ($self, $res) = @_;
    },
  );

From L<http://www.betalingsterminal.no/Netthandel-forside/Teknisk-veiledning/API/Query/>:

  To check the status of a transaction at any time, you can use the Query-call.

Useful C<$res> values:

=over 4

=item * $res->param("amount")

Holds the "amount" given to L</register_payment>.

=item * $res->param("amount_captured")

The amount which has been captured on this transaction.
This value is the "AmountCaptured" value devided by 100.

=item * $res->param("amount_credited")

The amount which has been credited on this transaction.
This value is the "AmountCredited" value devided by 100.

=item * $res->param("annulled")

Whether or not this transaction has been annulled.
Boolean true or false.

=item * $res->param("authorized")

Whether or not this transaction has been authorized.
Boolean true or false.

=item * $res->param("currency_code")

The currency code, following ISO 4217. Typical examples include "NOK" and
"USD". Often the same as L</currency_code>.

=item * $res->param("order_description")

Holds the "order_description" given to L</register_payment>.

=item * $res->param("order_number")

Holds the "order_number" given to L</register_payment>.

=item * $res->param("authorization_id")

Same as "authorization_id" from L</process_payment>.

=item * $res->param("customer_address1")

=item * $res->param("customer_address2")

=item * $res->param("customer_country")

=item * $res->param("customer_email")

=item * $res->param("customer_first_name")

=item * $res->param("customer_ip")

=item * $res->param("customer_last_name")

=item * $res->param("customer_number")

=item * $res->param("customer_phone_number")

=item * $res->param("customer_postcode")

=item * $res->param("expiry_date")

Which date the card expires on the format YYMM.

=item * $res->param("issuer_country")

Which country the card was issued, following ISO 3166.

=item * $res->param("masked_pan")

The personal account number used for this transaction, masked with asterisks.

=item * $res->param("payment_method")

Which payment method was used for this transaction. Examples: "Visa",
"MasterCard", "AmericanExpress", ...

=back

See also L</ERROR HANDLING>.

=cut

sub query_payment {
  my ($self, $c, $args, $cb) = @_;
  my $query_url = $self->_url('/Netaxept/Query.aspx');

  $args = { transaction_id => $args } unless ref $args;
  $args->{transaction_id} or return $self->$cb($self->_error('transaction_id missing in input'));

  $query_url->query({
    merchantId    => $self->merchant_id,
    token         => $self->token,
    transactionId => $args->{transaction_id},
  });

  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      $self->_ua->get($query_url, $delay->begin);
    },
    sub {
      my ($delay, $tx) = @_;
      my $res = Mojolicious::Plugin::NetsPayment::Res->new($tx->res);

      $res->code(0) unless $res->code;

      local $@;
      eval {
        my $body = $res->dom->at('PaymentInfo');

        $res->param(amount            => $body->at('OrderInformation > Amount')->text / 100);
        $res->param(amount_captured   => $body->at('Summary > AmountCaptured')->text / 100);
        $res->param(amount_credited   => $body->at('Summary > AmountCredited')->text / 100);
        $res->param(annuled           => $body->at('Summary > Annuled')->text eq 'true' ? 1 : 0);
        $res->param(authorized        => $body->at('Summary > Authorized')->text eq 'true' ? 1 : 0);
        $res->param(currency_code     => $body->at('OrderInformation > Currency')->text);
        $res->param(order_description => $body->at('OrderInformation > OrderDescription')->text);
        $res->param(order_number      => $body->at('OrderInformation > OrderNumber')->text);

        $res->param(authorization_id      => eval { $body->at('Summary > AuthorizationId')->text });
        $res->param(customer_address1     => eval { $body->at('CustomerInformation > Address1')->text });
        $res->param(customer_address2     => eval { $body->at('CustomerInformation > Address2')->text });
        $res->param(customer_country      => eval { $body->at('iCustomerInformation > Country')->text });
        $res->param(customer_email        => eval { $body->at('CustomerInformation > Email')->text });
        $res->param(customer_first_name   => eval { $body->at('CustomerInformation > FirstName')->text });
        $res->param(customer_ip           => eval { $body->at('CustomerInformation > IP')->text });
        $res->param(customer_last_name    => eval { $body->at('CustomerInformation > LastName')->text });
        $res->param(customer_number       => eval { $body->at('CustomerInformation > CustomerNumber')->text });
        $res->param(customer_phone_number => eval { $body->at('CustomerInformation > PhoneNumber')->text });
        $res->param(customer_postcode     => eval { $body->at('CustomerInformation > Postcode')->text });
        $res->param(expiry_date           => eval { $body->at('CardInformation > ExpiryDate')->text });
        $res->param(issuer_country        => eval { $body->at('CardInformation > IssuerCountry')->text });
        $res->param(masked_pan            => eval { $body->at('CardInformation > MaskedPAN')->text });
        $res->param(payment_method        => eval { $body->at('CardInformation > PaymentMethod')->text });
        1;
      } or do {
        warn "[MOJO_NETS] ! $@" if DEBUG;
        $self->_extract_error($res, $@);
      };

      $self->$cb($res);
    },
  );

  $self;
}

=head2 register_payment

  $self = $self->register_payment(
    $c,
    {
      amount => $num, # 99.90, not 9990
      order_number => $str,
      redirect_url => $str, # default to current request URL
      # ...
    },
    sub {
      my ($self, $res) = @_;
    },
  );

From L<http://www.betalingsterminal.no/Netthandel-forside/Teknisk-veiledning/API/Register/>:

  The purpose of the register call is to send all the data needed to
  complete a transaction to Netaxept servers. The input data is
  organized into a RegisterRequest, and the output data is formatted
  as a RegisterResponse.

NOTE: "amount" in this API need to be a decimal number, which will be duplicated with 100 to match
the Nets documentation.

There are many more options that can be passed on to L</register_payment>.
Look at L<http://www.betalingsterminal.no/Netthandel-forside/Teknisk-veiledning/API/Register/>
for a complete list. CamelCase arguments can be given in normal form. Examples:

  # NetsDocumentation   | perl_argument_name
  # --------------------|----------------------
  # currencyCode        | currency_code
  # customerPhoneNumber | customer_phone_number

Useful C<$res> values:

=over 4

=item * $res->code

Set to 302 on success.

=item * $res->param("transaction_id")

Only set on success. An ID identifying this transaction. Generated by Nets.

=item * $res->headers->location

Only set on success. This holds a URL to the Nets terminal page, which
you will redirect the user to after storing the transaction ID and other
customer related details.

=back

=cut

sub register_payment {
  my ($self, $c, $args, $cb) = @_;
  my $register_url = $self->_url('/Netaxept/Register.aspx');

  $args->{amount}       or return $self->$cb($self->_error('amount missing in input'));
  $args->{order_number} or return $self->$cb($self->_error('order_number missing in input'));
  local $args->{amount} = $args->{amount} * 100;
  local $args->{redirect_url} ||= $c->req->url->to_abs;

  $register_url->query({
    currencyCode        => $self->currency_code,
    merchantId          => $self->merchant_id,
    token               => $self->token,
    environmentLanguage => 'perl',
    OS                  => $^O || 'Mojolicious',
    $self->_camelize($args),
  });

  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      $self->_ua->get($register_url, $delay->begin);
    },
    sub {
      my ($delay, $tx) = @_;
      my $res = Mojolicious::Plugin::NetsPayment::Res->new($tx->res);

      $res->code(0) unless $res->code;

      local $@;
      eval {
        my $id = $res->dom->at('RegisterResponse > TransactionId')->text;
        my $terminal_url = $self->_url('/Terminal/default.aspx')->query({merchantId => $self->merchant_id, transactionId => $id});

        $res->headers->location($terminal_url);
        $res->param(transaction_id => $id);
        $res->code(302);
        1;
      } or do {
        warn "[MOJO_NETS] ! $@" if DEBUG;
        $self->_extract_error($res, $@);
      };

      $self->$cb($res);
    },
  );

  $self;
}

=head2 register

  $app->plugin(NetsPayment => \%config);

Called when registering this plugin in the main L<Mojolicious> application.

=cut

sub register {
  my ($self, $app, $config) = @_;

  # self contained
  if (ref $config->{token}) {
    $self->_add_routes($app);
    $self->_ua->server->app($app);
    $config->{token} = ${ $config->{token} };
  }
  elsif ($app->mode eq 'production') {
    $config->{base_url} ||= 'https://epayment.nets.eu';
  }

  # copy config to this object
  for (grep { $self->$_ } keys %$config) {
    $self->{$_} = $config->{$_};
  }

  $app->helper(
    nets => sub {
      my $c = shift;
      return $self unless @_;
      my $method = shift .'_payment';
      $self->$method($c, @_);
      return $c;
    }
  );
}

sub _add_routes {
  my ($self, $app) = @_;
  my $r = $app->routes;
  my $payments = $self->{payments} ||= {}; # just here for debug purposes, may change without warning

  $self->base_url('/nets');

  $r->get('/nets/Netaxept/Process.aspx', { template => 'nets/Netaxept/Process', format => 'xml' });
  $r->get('/nets/Netaxept/Query.aspx', { template => 'nets/Netaxept/Query', format => 'xml' });
  $r->get('/nets/Netaxept/Register.aspx')->to(cb => sub {
    my $self = shift;
    my $txn_id = 'b127f98b77f741fca6bb49981ee6e846';
    $payments->{$txn_id} = $self->req->query_params->to_hash;
    $self->render('nets/Netaxept/Register', txn_id => $txn_id, format => 'xml');
  });
  $r->get('/nets/Terminal/default.aspx')->to(cb => sub {
    my $self = shift;
    my $txn_id = $self->param('transactionId') || 'missing';
    $self->render('nets/Terminal/default', format => 'html', payment => $payments->{$txn_id});
  });

  push @{ $app->renderer->classes }, __PACKAGE__;
}

sub _camelize {
  my ($self, $args) = @_;
  map { my $k = $_; s/_([a-z])/\U$1/g; ($_ => $args->{$k}); } keys %$args;
}

sub _error {
  my ($self, $err) = @_;
  my $res = Mojolicious::Plugin::NetsPayment::Res->new;
  $res->code(400);
  $res->param(message => $err);
  $res->param(source => __PACKAGE__);
  $res;
}

sub _extract_error {
  my ($self, $res, $e) = @_;
  my $err;

  local $@;
  $err = eval { $_[0]->res->dom->Exception->Error->Message->text };

  $res->code(500);
  $res->param(code => '') unless $res->param('code');
  $res->param(message => $err // $e);
  $res->param(source => $err ? $self->base_url : __PACKAGE__);
}

sub _url {
  my $url = Mojo::URL->new($_[0]->base_url .$_[1]);
  warn "[MOJO_NETS] URL $url\n" if DEBUG;
  $url;
}

package
  Mojolicious::Plugin::NetsPayment::Res;
use Mojo::Base 'Mojo::Message::Response';
sub param { shift->body_params->param(@_) }

=head1 ERROR HANDLING

There are some generic error handling in this module: The C<$res> object
passed on to the callbacks will have "source" and "message" set. These can
be retrived using the code below:

  $int = $res->code; # will be 500 on exception
  $str = $res->param("source");
  $str = $res->param("message");

The "source" might have to special values:

=over 4

=item * Same as L</base_url>.

If the "source" is set to the value of L</base_url> then the "message"
will contain an exception from Nets.

=item * "Mojolicious::Plugin::NetsPayment"

If the "source" is set to this package name, then the "message" will be an
exception from parse error.

=back

=head1 SEE ALSO

=over 4

=item * Overview

L<http://www.betalingsterminal.no/Netthandel-forside/Teknisk-veiledning/Overview/>

=item * API

L<http://www.betalingsterminal.no/Netthandel-forside/Teknisk-veiledning/API/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;

package Mojolicious::Plugin::NetsPayment;
__DATA__
@@ layouts/nets.html.ep
<!DOCTYPE html>
<html>
<head>
  <title>Nets terminal</title>
</head>
<body>
%= content
</body>
</html>

@@ nets/Netaxept/Process.xml.ep
<?xml version="1.0" ?>
<ProcessResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <Operation>AUTH</Operation>
  <ResponseCode>OK</ResponseCode>
  <AuthorizationId>064392</AuthorizationId>
  <TransactionId>b127f98b77f741fca6bb49981ee6e846</TransactionId>
  <ExecutionTime>2009-12-16T11:17:54.633125+01:00</ExecutionTime>
  <MerchantId>9999997</MerchantId>
</ProcessResponse>

@@ nets/Netaxept/Query.xml.ep
<?xml version="1.0" ?>
<PaymentInfo xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <MerchantId>9999997</MerchantId>
  <TransactionId>b127f98b77f741fca6bb49981ee6e846</TransactionId>
  <QueryFinished>2009-12-16T15:18:30.445625+01:00</QueryFinished>
  <OrderInformation>
    <Amount>200</Amount>
    <Currency>NOK</Currency>
    <OrderNumber>10011</OrderNumber>
    <OrderDescription></OrderDescription>
  </OrderInformation>
  <CustomerInformation>
    <Email>jhthorsen@cpan.org</Email>
    <IP>91.102.26.94</IP>
    <PhoneNumber></PhoneNumber>
    <FirstName>Jan Henning</FirstName>
    <LastName>Thorsen</LastName>
    <CustomerNumber></CustomerNumber>
  </CustomerInformation>
  <Summary>
    <AmountCaptured>200</AmountCaptured>
    <AmountCredited>0</AmountCredited>
    <Annuled>false</Annuled>
    <Authorized>true</Authorized>
    <AuthorizationId>064392</AuthorizationId>
  </Summary>
  <CardInformation>
    <IssuerCountry>NO</IssuerCountry>
    <MaskedPAN>492500******0004</MaskedPAN>
    <PaymentMethod>Visa</PaymentMethod>
    <ExpiryDate>1212</ExpiryDate>
  </CardInformation>
  <History>
    <TransactionLogLine>
      <DateTime>2009-12-16T10:26:47.243</DateTime>
      <Description />
      <Operation>Register</Operation>
      <TransactionReconRef />
    </TransactionLogLine>
    <TransactionLogLine>
      <DateTime>2009-12-16T11:17:54.633</DateTime>
      <Operation>Auth</Operation>
      <BatchNumber>555</BatchNumber>
      <TransactionReconRef />
    </TransactionLogLine>
    <TransactionLogLine>
      <Amount>200</Amount>
      <DateTime>2009-12-16T11:40:57.603</DateTime>
      <Description />
      <Operation>Capture</Operation>
      <BatchNumber>555</BatchNumber>
      <TransactionReconRef />
    </TransactionLogLine>
  </History>
  <ErrorLog />
  <AuthenticationInformation />
  <AvtaleGiroInformation />
</PaymentInfo>

@@ nets/Netaxept/Register.xml.ep
<?xml version="1.0" ?>
<RegisterResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <TransactionId><%= $txn_id %></TransactionId>
</RegisterResponse>

@@ nets/Terminal/default.html.ep
% layout 'nets';
<h1>Netaxept</h1>
<p>This is a dummy terminal. Obviously.</p>
<dl>
  <dt>Merchant</dt><dd><%= $payment->{merchantId} %></dd>
  <dt>Amount</dt><dd><%= sprintf '%.02f', $payment->{amount} / 100 %> <%= $payment->{currencyCode} %></dd>
  <dt>Order number</dt><dd><%= $payment->{orderNumber} %></dd>
</dl>
<p>
  %= link_to 'Complete payment', url_for($payment->{redirectUrl})->query({ transactionId => param('transactionId'), responseCode => 'OK' }), class => 'back'
</p>
