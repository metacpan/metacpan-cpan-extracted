use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  plugin 'StripePayment' => {mocked => 1};
  post '/charge' => sub {
    my $c = shift;
    $c->delay(
      sub { $c->stripe->create_charge({}, shift->begin) },
      sub {
        my ($delay, $err, $res) = @_;
        $c->render(json => $err ? {oops => $err} : $res);
      }
    );
  };
}

my $t = Test::Mojo->new;
my %form;

$form{amount}      = 100;
$form{stripeToken} = 'tok_42';
$t->post_ok('/charge', form => \%form)->status_is(200)->json_is('/captured', Mojo::JSON->true);

local $Mojolicious::Plugin::StripePayment::MOCKED_RESPONSE = {
  status => 400,
  json   => {error => {message => 'Invalid boolean: 0', param => 'capture', type => 'invalid_request_error'}}
};
$t->post_ok('/charge', form => \%form)->status_is(200)->json_is('/oops', 'capture: Invalid boolean: 0');

done_testing;
