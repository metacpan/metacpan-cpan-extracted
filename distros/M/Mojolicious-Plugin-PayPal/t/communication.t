use Mojo::Base -base;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  plugin PayPal => { secret => \ "dummy" };

  # register a payment and send the visitor to PayPal payment terminal
  post '/checkout' => sub {
    my $self = shift->render_later;
    my %payment = (
      amount => scalar $self->param('amount'),
      description => 'Some description',
    );

    Mojo::IOLoop->delay(
      sub {
        my ($delay) = @_;
        $self->paypal(register => \%payment, $delay->begin);
      },
      sub {
        my ($delay, $res) = @_;
        $self->render(
          json => {
            message => scalar $res->param('message'),
            source => scalar $res->param('source'),
            transaction_id => scalar $res->param('transaction_id'),
            location => $res->headers->location,
          },
          status => $res->code,
        );
      },
    );
  };

  # after redirected back from PayPal payment terminal
  get '/checkout' => sub {
    my $self = shift->render_later;

    Mojo::IOLoop->delay(
      sub {
        my ($delay) = @_;
        $self->paypal(process => {}, $delay->begin);
      },
      sub {
        my ($delay, $res) = @_;
        $self->render(
          json => {
            message => scalar $res->param('message'),
            source => scalar $res->param('source'),
            payer_id => scalar $res->param('payer_id'),
            transaction_id => scalar $res->param('transaction_id'),
          },
          status => $res->code,
        );
      },
    );
  };
}

my $t = Test::Mojo->new;
my (@tx, $url);

$t->app->paypal->_ua->on(start => sub { push @tx, pop });

{
  diag 'Step 1';
  @tx = ();
  $t->post_ok('/checkout')
    ->status_is(400)
    ->json_is('/source', 'Mojolicious::Plugin::PayPal')
    ->json_is('/message', 'amount missing in input')
    ->json_is('/transaction_id', undef)
    ;

  @tx = ();
  $t->post_ok('/checkout?amount=100')
    ->status_is(302)
    ->json_is('/advice', undef)
    ->json_is('/message', undef)
    ->json_is('/transaction_id', 'PAY-6RV70583SB702805EKEYSZ6Y')
    ;

  $url = $tx[0]->req->url;
  diag "paypal oauth2 url=$url";
  is $url->path, '/paypal/v1/oauth2/token', '/paypal/v1/oauth2/token';

  $url = $tx[1]->req->url;
  diag "paypal register url=$url";
  is $url->path, '/paypal/v1/payments/payment', '/paypal/v1/payments/payment';
}

{
  $url = Mojo::URL->new($t->tx->res->json->{location});
  diag "paypal terminal url=$url";
  is $url->path, '/paypal/webscr', '/paypal/webscr';

  diag 'Step 2';
  $t->get_ok($url)
    ->status_is(200)
    ->element_exists('a.back', 'link back to merchant page')
    ->text_is('dl dd:nth-of-type(1)', '100 USD', 'terminal amount')
    ->text_is('dl dd:nth-of-type(2)', 'paypal', 'terminal payment method')
    ;
}

{
  diag 'Step 2.5';
  $url = Mojo::URL->new($t->tx->res->dom->at('a.back')->{href});

  diag $url;
  is $url->path, '/checkout', '/checkout';
  is $url->query->param('token'), 'EC-60U79048BN7719609', 'token=EC-60U79048BN7719609';
  is $url->query->param('PayerID'), '42', 'PayerID=42';

  # params from the original test url
  is $url->query->param('return_url'), '1', 'return_url=1';

  diag 'Step 3 + 4';
  $t->get_ok($url)
    ->status_is(200)
    ->json_is('/payer_id', '42')
    ->json_is('/transaction_id', 'PAY-6RV70583SB702805EKEYSZ6Y')
    ;
}

done_testing;
