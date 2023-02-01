package Net::Payjp;

use strict;
use warnings;

use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request::Common;
use JSON;
use List::Util qw/min/;
use POSIX qw/floor/;

use Net::Payjp::Account;
use Net::Payjp::Charge;
use Net::Payjp::Customer;
use Net::Payjp::Plan;
use Net::Payjp::Subscription;
use Net::Payjp::Token;
use Net::Payjp::Transfer;
use Net::Payjp::Event;
use Net::Payjp::Tenant;
use Net::Payjp::TenantTransfer;
use Net::Payjp::Object;

# ABSTRACT: API client for pay.jp

=head1 SYNOPSIS

 # Create charge
 my $payjp = Net::Payjp->new(api_key => $API_KEY);
 my $res = $payjp->charge->create(
   card => 'token_id_by_Checkout_or_payjp.js',
   amount => 3500,
   currency => 'jpy',
 );
 if(my $e = $res->error){
   print "Error;
   print $e->{message}."\n";
 }
 # Id of charge.
 print $res->id;

 # Retrieve a charge
 $payjp->id($res->id); # Set id of charge
 $res = $payjp->charge->retrieve; # or $payjp->charge->retrieve($res->id);

=head1 DESCRIPTION

This module is a wrapper around the Pay.jp HTTP API.Methods are generally named after the object name and the acquisition method.

This method returns json objects for responses from the API.

=head1 new Method

This creates a new Payjp api object. The following parameters are accepted:

=over

=item api_key

This is required. You get this from your Payjp Account settings.

=back

=cut

our $VERSION = '0.2.2';
our $API_BASE = 'https://api.pay.jp';
our $INITIAL_DELAY_SEC = 2;
our $MAX_DELAY_SEC = 32;

sub new{
  my $self = shift;
  bless{__PACKAGE__->_init(@_)},$self;
}

sub _init{
  my $self = shift;
  my %p = @_;
  return(
    api_key  => $p{api_key},
    id       => $p{id},
    api_base => $API_BASE,
    max_retry     => $p{max_retry} || 0,
    initial_delay => $p{initial_delay} || $INITIAL_DELAY_SEC,
    max_delay     => $p{max_delay} || $MAX_DELAY_SEC,
  );
}

sub api_key{
  my $self = shift;
  $self->{api_key} = shift if @_;
  return $self->{api_key};
}

sub api_base{
  my $self = shift;
  $self->{api_base} = shift if @_;
  return $self->{api_base};
}

sub id{
  my $self = shift;
  $self->{id} = shift if @_;
  return $self->{id};
}

=head1 Charge Methods

=head2 create

Create a new charge

L<https://pay.jp/docs/api/#支払いを作成>

 $payjp->charge->create(
   card => 'tok_76e202b409f3da51a0706605ac81',
   amount => 3500,
   currency => 'jpy',
   description => 'yakiimo',
 );

=head2 retrieve

Retrieve a charge

L<https://pay.jp/docs/api/#支払いを情報を取得>

 $payjp->charge->retrieve('ch_fa990a4c10672a93053a774730b0a');

=head2 save

Update a charge

L<https://pay.jp/docs/api/#支払いを情報を取得>

 $payjp->id('ch_fa990a4c10672a93053a774730b0a');
 $payjp->charge->save(description => 'update description.');

=head2 refund

Refund a charge

L<https://pay.jp/docs/api/#返金する>

 $payjp->id('ch_fa990a4c10672a93053a774730b0a');
 $payjp->charge->refund(amount => 1000, refund_reason => 'test.');

=head2 capture

Capture a charge

L<https://pay.jp/docs/api/#支払い処理を確定する>

 $payjp->id('ch_fa990a4c10672a93053a774730b0a');
 $payjp->charge->capture(amount => 2000);

=head2 all

Returns the charge list

L<https://pay.jp/docs/api/#支払いリストを取得>

 $payjp->charge->all("limit" => 2, "offset" => 1);

=head1 Customer Methods

=head2 create

Create a cumtomer

L<https://pay.jp/docs/api/#顧客を作成>

 $payjp->customer->create(
   "description" => "test",
 );

=head2 retrieve

Retrieve a customer

L<https://pay.jp/docs/api/#顧客情報を取得>

 $payjp->customer->retrieve('cus_121673955bd7aa144de5a8f6c262');

=head2 save

Update a customer

L<https://pay.jp/docs/api/#顧客情報を更新>

 $payjp->id('cus_121673955bd7aa144de5a8f6c262');
 $payjp->customer->save(email => 'test@test.jp');

=head2 delete

Delete a customer

L<https://pay.jp/docs/api/#顧客を削除>

 $payjp->id('cus_121673955bd7aa144de5a8f6c262');
 $payjp->customer->delete;

=head2 all

Returns the customer list

L<https://pay.jp/docs/api/#顧客リストを取得>

$res = $payjp->customer->all(limit => 2, offset => 1);

=cut

sub charge{
  my $self = shift;
  return Net::Payjp::Charge->new(%$self);
}

=head1 Cutomer card Methods

Returns a customer's card object

 my $card = $payjp->customer->card('cus_4df4b5ed720933f4fb9e28857517');

=head2 create

Create a customer's card

L<https://pay.jp/docs/api/#顧客のカードを作成>

 $card->create(
   card => 'tok_76e202b409f3da51a0706605ac81'
 );

=head2 retrieve

Retrieve a customer's card

L<https://pay.jp/docs/api/#顧客のカード情報を取得>

 $card->retrieve('car_f7d9fa98594dc7c2e42bfcd641ff');

=head2 save

Update a customer's card

L<https://pay.jp/docs/api/#顧客のカードを更新>

$card->id('car_f7d9fa98594dc7c2e42bfcd641ff');
$card->save(exp_year => "2026", exp_month => "05", name => 'test');

=head2 delete

Delete a customer's card

L<https://pay.jp/docs/api/#顧客のカードを削除>

 $card->id('car_f7d9fa98594dc7c2e42bfcd641ff');
 $card->delete;

=head2 all

Returns the customer's card list

L<https://pay.jp/docs/api/#顧客のカードリストを取得>

 $card->all(limit => 2, offset => 0);

=head1 Customer subscription Methods

Returns a customer's subscription object

 my $subscription = $payjp->customer->subscription('sub_567a1e44562932ec1a7682d746e0');

=head2 retrieve

Retrieve a customer's subscription

L<https://pay.jp/docs/api/#顧客の定期課金情報を取得>

 $subscription->retrieve('sub_567a1e44562932ec1a7682d746e0');

=head2 all

Returns the customer's subscription list

L<https://pay.jp/docs/api/#顧客の定期課金リストを取得>

$subscription->all(limit => 1, offset => 0);

=cut

sub customer{
  my $self = shift;
  return Net::Payjp::Customer->new(%$self);
}

=head1 Plan Methods

=head2 create

Create a plan

L<https://pay.jp/docs/api/#プランを作成>

 $payjp->plan->create(
   amount => 500,
   currency => "jpy",
   interval => "month",
   trial_days => 30,
   name => 'test_plan'
 );

=head2 retrieve

Retrieve a plan

L<https://pay.jp/docs/api/#プラン情報を取得>

 $payjp->plan->retrieve('pln_45dd3268a18b2837d52861716260');

=head2 save

Update a plan

L<https://pay.jp/docs/api/#プランを更新>

 $payjp->id('pln_45dd3268a18b2837d52861716260');
 $payjp->plan->save(name => 'NewPlan');

=head2 delete

Delete a plan

L<https://pay.jp/docs/api/#プランを削除>

 $payjp->id('pln_45dd3268a18b2837d52861716260');
 $payjp->plan->delete;

=head2 all

Returns the plan list

L<https://pay.jp/docs/api/#プランリストを取得>

 $payjp->plan->all("limit" => 5, "offset" => 0);

=cut

sub plan{
  my $self = shift;
  return Net::Payjp::Plan->new(%$self);
}

=head1 Subscription Methods

=head2 create

Create a subscription

L<https://pay.jp/docs/api/#定期課金を作成>

 $payjp->subscription->create(
   customer => 'cus_4df4b5ed720933f4fb9e28857517',
   plan => 'pln_9589006d14aad86aafeceac06b60'
 );

=head2 retrieve

Retrieve a subscription

L<https://pay.jp/docs/api/#定期課金情報を取得>

 $payjp->subscription->retrieve('sub_567a1e44562932ec1a7682d746e0');

=head2 save

Update a subscription

L<https://pay.jp/docs/api/#定期課金を更新>

 $payjp->id('sub_567a1e44562932ec1a7682d746e0');
 $payjp->subscription->save(trial_end => 1473911903);

=head2 pause

Pause a subscription

L<https://pay.jp/docs/api/#定期課金を停止>

 $payjp->id('sub_567a1e44562932ec1a7682d746e0');
 $payjp->subscription->pause;

=head2 resume

Resume a subscription

L<https://pay.jp/docs/api/#定期課金を再開>

 $payjp->id('sub_567a1e44562932ec1a7682d746e0');
 $payjp->subscription->resume;

=head2 cancel

Cancel a subscription

L<https://pay.jp/docs/api/#定期課金をキャンセル>

 $payjp->id('sub_567a1e44562932ec1a7682d746e0');
 $payjp->subscription->cancel;

=head2 delete

Delete a subscription

L<https://pay.jp/docs/api/#定期課金を削除>

 $payjp->id('sub_567a1e44562932ec1a7682d746e0');
 $payjp->subscription->delete;

=head2 all

Returns the subscription list

L<https://pay.jp/docs/api/#定期課金のリストを取得>

 $payjp->subscription->all(limit => 3, offset => 0);

=cut

sub subscription{
  my $self = shift;
  return Net::Payjp::Subscription->new(%$self);
}

=head1 Token Methods

=head2 retrieve

Retrieve a token

L<https://pay.jp/docs/api/#トークン情報を取得>

$payjp->token->retrieve('tok_eff34b780cbebd61e87f09ecc9c6');

=cut

sub token{
  my $self = shift;
  return Net::Payjp::Token->new(%$self);
}

=head1 Transfer Methods

=head2 retrieve

Retrieve a transfer

L<https://pay.jp/docs/api/#入金情報を取得>

 $payjp->transfer->retrieve('tr_8f0c0fe2c9f8a47f9d18f03959ba1');

=head2 all

Returns the transfer list

L<https://pay.jp/docs/api/#入金リストを取得>

 $payjp->transfer->all("limit" => 3, offset => 0);

=head2 charges

Returns the charge list

L<https://pay.jp/docs/api/#入金の内訳を取得>

 $payjp->transfer->charges(
   limit => 3,
   offset => 0
 );

=cut

sub transfer{
  my $self = shift;
  return Net::Payjp::Transfer->new(%$self);
}

=head1 Event Methods

=head2 retrieve

Retrieve a event

L<https://pay.jp/docs/api/#イベント情報を取得>

 $res = $payjp->event->retrieve('evnt_2f7436fe0017098bc8d22221d1e');

=head2 all

Returns the event list

L<https://pay.jp/docs/api/#イベントリストを取得>

$payjp->event->all(limit => 10, offset => 0);

=cut

sub event{
  my $self = shift;
  return Net::Payjp::Event->new(%$self);
}

=head1 Account Methods

=head2 retrieve

Retrieve a account

L<https://pay.jp/docs/api/#アカウント情報を取得>

 $payjp->account->retrieve;

=cut

sub account{
  my $self = shift;
  return Net::Payjp::Account->new(%$self);
}

sub tenant{
  my $self = shift;
  return Net::Payjp::Tenant->new(%$self);
}

sub tenant_transfer{
  my $self = shift;
  return Net::Payjp::TenantTransfer->new(%$self);
}

sub _request{
  my $self = shift;
  my %p = @_;

  my $url = $p{url};
  my $method = $p{method} || 'GET';
  my $retry = $p{retry} || 0;

  my $req;
  my $with_param;
  if(ref $p{param} eq 'HASH' and keys %{$p{param}} > 0) {
    $with_param = 1;
  }
  if($with_param and ($method eq 'GET' or $method eq 'DELETE')){
    my @param;
    foreach my $k(keys %{$p{param}}){
      push(@param, "$k=".$p{param}->{$k});
    }
    $url .= '?'.join("&", @param);
  }
  if($method eq 'POST' and $with_param){
    $req = POST($url, $self->_api_param(param => $p{param}));
  } else {
    $req = new HTTP::Request $method => $url;
  }

  $req->authorization_basic($self->api_key, '');
  my $ua = LWP::UserAgent->new();
  $ua->timeout(30);
  my $client = {
    'bindings_version' => $VERSION,
    'lang' => 'perl',
    'lang_version' => $],
    'publisher' => 'payjp',
    'uname' => $^O
  };
  $ua->default_header(
    'User-Agent' => 'Payjp/v1 PerlBindings/'.$VERSION,
    'X-Payjp-Client-User-Agent' => JSON->new->encode($client),
  );

  my $res = $ua->request($req);
  my $code = $res->code;
  if($code == 200){
    my $obj = $self->_to_object(JSON->new->decode($res->content));
    $self->id($obj->id) if $obj->id;
    return $obj;
  } elsif($code == 429 and $retry < $self->{max_retry}){
    sleep($self->_get_delay_sec(
      retry => $retry,
      init_sec => $self->{initial_delay},
      max_sec => $self->{max_delay}
    ));
    return $self->_request(method => $method, url =>$url, param => $p{param}, retry => $retry + 1);
  } elsif($code =~ /^4/){
    return $self->_to_object(JSON->new->decode($res->content));
  }
  return $self->_to_object(
    {
      error => {
        message => $res->message,
        status_code => $code,
      }
    }
  );
}

sub _get_delay_sec {
  my $self = shift;
  my %p = @_;
  my $retry = $p{retry}; # number
  my $init_sec = $p{init_sec}; # number
  my $max_sec = $p{max_sec}; # number

  return min($init_sec * 2 ** $retry, $max_sec) / 2 * (1 + rand(1));
}

sub _to_object{
  my $self = shift;
  my $hash = shift;

  return Net::Payjp::Object->new(%$hash);
}

sub _api_param{
  my $self = shift;
  my %p = @_;
  my $param = $p{param};

  my $req_param;
  foreach my $k(keys(%{$param})){
    if(ref($param->{$k}) eq 'HASH'){
      foreach(keys(%{$param->{$k}})){
        $req_param->{$k.'['.$_.']'} = $param->{$k}->{$_};
      }
    }
    else{
      $req_param->{$k} = $param->{$k};
    }
  }
  return $req_param;
}

sub _instance_url{
  my $self = shift;
  return $self->_class_url.'/'.($self->id or '');
}

sub _class_url{
  my $self = shift;
  my ($class) = lc(ref($self)) =~ /([^:]*$)/;
  return $self->api_base.'/v1/'.$class.'s';
}

1;
