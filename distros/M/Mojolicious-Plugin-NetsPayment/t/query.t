use Mojo::Base -base;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  plugin NetsPayment => { token => \ "dummy" };

  get '/query' => sub {
    my $self = shift->render_later;

    Mojo::IOLoop->delay(
      sub {
        my ($delay) = @_;
        $self->nets(query => { transaction_id => 'b127f98b77f741fca6bb49981ee6e846' }, $delay->begin);
      },
      sub {
        my ($delay, $res) = @_;
        $self->render(json => $res->body_params->to_hash);
      },
    );
  };
}

my $t = Test::Mojo->new;
my (@tx, $url);

{
  $t->get_ok('/query')
    ->status_is(200)
    ->json_is('/message', undef)
    ->json_is('/source', undef)
    ->json_is('/amount', 2)
    ->json_is('/amount_captured', 2)
    ->json_is('/amount_credited', 0)
    ->json_is('/annuled', 0)
    ->json_is('/authorized', 1)
    ->json_is('/currency_code', 'NOK')
    ->json_is('/order_description', '')
    ->json_is('/order_number', '10011')

    ->json_is('/authorization_id', '064392')
    ->json_is('/customer_address1', undef)
    ->json_is('/customer_address2', undef)
    ->json_is('/customer_country', undef)
    ->json_is('/customer_email', 'jhthorsen@cpan.org')
    ->json_is('/customer_first_name', 'Jan Henning')
    ->json_is('/customer_ip', '91.102.26.94')
    ->json_is('/customer_last_name', 'Thorsen')
    ->json_is('/customer_number', '')
    ->json_is('/customer_phone_number', '')
    ->json_is('/customer_postcode', undef)
    ->json_is('/expiry_date', '1212')
    ->json_is('/issuer_country', 'NO')
    ->json_is('/masked_pan', '492500******0004')
    ->json_is('/payment_method', 'Visa')
    ;
}

done_testing;
