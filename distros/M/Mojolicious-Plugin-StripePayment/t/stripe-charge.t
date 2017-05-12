use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  plugin 'StripePayment' => {mocked => 1};
  post '/charge' => sub {
    my $c = shift;
    $c->delay(
      sub { $c->stripe->create_charge({capture => $c->param('capture')}, shift->begin) },
      sub {
        my ($delay, $err, $res) = @_;
        return $c->render(json => {oops => $err}) if $err;
        return $c->render(json => $res) unless 0 == ($c->param('capture') // 1);
        return $c->stripe->capture_charge({id => $res->{id}}, $delay->begin);
      },
      sub {
        my ($delay, $err, $res) = @_;
        $res->{capture_charge} = 'called';
        $c->render(json => $err ? {oops => $err} : $res);
      }
    );
  };
}

my $t = Test::Mojo->new;
my %form;

$t->post_ok('/charge', form => \%form)->status_is(200)->json_is('/oops', 'amount is required');
$form{amount} = 100;
$t->post_ok('/charge', form => \%form)->status_is(200)->json_is('/oops', 'source/token is required');

$form{stripeToken} = 'tok_42';
$t->post_ok('/charge', form => \%form)->status_is(200)->json_is('/captured', Mojo::JSON->true)
  ->json_is('/id', 'ch_15ceESLV2Qt9u2twk0Arv0Z8')->json_is('/receipt_email', undef);

$form{stripeToken} = 'tok_42';
$form{stripeEmail} = 'bruce@example.com';
$t->post_ok('/charge', form => \%form)->status_is(200)->json_is('/captured', Mojo::JSON->true)
  ->json_is('/id', 'ch_15ceESLV2Qt9u2twk0Arv0Z8')->json_is('/receipt_email', 'bruce@example.com');

$form{capture} = 0;
$t->post_ok('/charge', form => \%form)->status_is(200)->json_is('/captured', Mojo::JSON->true)
  ->json_is('/capture_charge', 'called');

done_testing;
